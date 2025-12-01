package com.example.camera_connect

import android.util.Log
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.Socket
import java.net.SocketTimeoutException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.*

/**
 * Camera Discovery Service
 * Discovers PTP/IP cameras on the network using multiple methods
 */
class CameraDiscovery(
    private val logger: (String, String, String?) -> Unit = { _, _, _ -> }
) {
    companion object {
        private const val TAG = "CameraDiscovery"
        
        // PTP/IP default port
        private const val PTPIP_PORT = 15740
        
        // Discovery timeout
        private const val DISCOVERY_TIMEOUT = 5000
        private const val SOCKET_TIMEOUT = 1000
        
        // Common camera IP patterns
        private val COMMON_CAMERA_IPS = listOf(
            "192.168.0.1",      // Sony, Fuji
            "192.168.1.1",      // Canon, Nikon
            "192.168.0.10",     // Some Sony
            "192.168.1.2",      // Some Canon
            "192.168.43.1",     // Hotspot mode
            "172.16.0.1",       // Some cameras
            "10.0.0.1",         // Alternative
        )
        
        // Common camera subnet patterns for scanning
        private val COMMON_SUBNETS = listOf(
            "192.168.0.",
            "192.168.1.",
            "192.168.43.",
        )
    }
    
    data class DiscoveredCamera(
        val ipAddress: String,
        val port: Int = PTPIP_PORT,
        val name: String? = null,
        val manufacturer: String? = null,
        val discoveryMethod: String
    )
    
    private val discoveredCameras = ConcurrentHashMap<String, DiscoveredCamera>()
    
    /**
     * Discover cameras on the network
     * Returns list of discovered cameras
     */
    suspend fun discoverCameras(
        onCameraFound: (DiscoveredCamera) -> Unit = {}
    ): List<DiscoveredCamera> = withContext(Dispatchers.IO) {
        discoveredCameras.clear()
        log("INFO", "Starting camera discovery...")
        
        val jobs = mutableListOf<Job>()
        
        // Method 1: Check common camera IPs first (fastest)
        jobs.add(launch {
            checkCommonIPs(onCameraFound)
        })
        
        // Method 2: Scan local subnet
        jobs.add(launch {
            delay(500) // Give common IPs a head start
            scanLocalSubnet(onCameraFound)
        })
        
        // Method 3: Try to find camera via ARP/network interfaces
        jobs.add(launch {
            checkNetworkInterfaces(onCameraFound)
        })
        
        // Wait for all discovery methods with timeout
        withTimeoutOrNull(DISCOVERY_TIMEOUT.toLong()) {
            jobs.forEach { it.join() }
        }
        
        val cameras = discoveredCameras.values.toList()
        log("SUCCESS", "Discovery complete. Found ${cameras.size} camera(s)")
        
        cameras
    }
    
    /**
     * Quick check of common camera IP addresses
     */
    private suspend fun checkCommonIPs(onCameraFound: (DiscoveredCamera) -> Unit) {
        log("DEBUG", "Checking common camera IPs...")
        
        coroutineScope {
            COMMON_CAMERA_IPS.map { ip ->
                async {
                    if (checkPtpIpPort(ip)) {
                        val camera = DiscoveredCamera(
                            ipAddress = ip,
                            port = PTPIP_PORT,
                            discoveryMethod = "common_ip"
                        )
                        addCamera(camera, onCameraFound)
                    }
                }
            }.awaitAll()
        }
    }
    
    /**
     * Scan local subnet for cameras
     */
    private suspend fun scanLocalSubnet(onCameraFound: (DiscoveredCamera) -> Unit) {
        val localIp = getLocalIpAddress() ?: return
        log("DEBUG", "Local IP: $localIp")
        
        // Get subnet from local IP
        val subnet = localIp.substringBeforeLast(".") + "."
        log("DEBUG", "Scanning subnet: $subnet*")
        
        coroutineScope {
            // Scan common addresses in the subnet (1-20, and gateway addresses)
            val addressesToScan = (1..20).map { "$subnet$it" } +
                listOf("${subnet}100", "${subnet}254")
            
            addressesToScan.map { ip ->
                async {
                    if (ip != localIp && checkPtpIpPort(ip)) {
                        val camera = DiscoveredCamera(
                            ipAddress = ip,
                            port = PTPIP_PORT,
                            discoveryMethod = "subnet_scan"
                        )
                        addCamera(camera, onCameraFound)
                    }
                }
            }.awaitAll()
        }
    }
    
    /**
     * Check network interfaces for camera connections
     */
    private fun checkNetworkInterfaces(onCameraFound: (DiscoveredCamera) -> Unit) {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                
                // Look for WiFi direct or camera hotspot interfaces
                val name = networkInterface.name.lowercase()
                if (name.contains("wlan") || name.contains("p2p") || name.contains("wifi")) {
                    val addresses = networkInterface.inetAddresses
                    while (addresses.hasMoreElements()) {
                        val address = addresses.nextElement()
                        if (!address.isLoopbackAddress && address.hostAddress?.contains(".") == true) {
                            val ip = address.hostAddress ?: continue
                            log("DEBUG", "Found interface: $name -> $ip")
                            
                            // Try gateway addresses
                            val subnet = ip.substringBeforeLast(".")
                            listOf("$subnet.1", "$subnet.0").forEach { gatewayIp ->
                                if (checkPtpIpPort(gatewayIp)) {
                                    val camera = DiscoveredCamera(
                                        ipAddress = gatewayIp,
                                        port = PTPIP_PORT,
                                        discoveryMethod = "interface_gateway"
                                    )
                                    addCamera(camera, onCameraFound)
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            log("DEBUG", "Error checking network interfaces: ${e.message}")
        }
    }
    
    /**
     * Check if PTP/IP port is open on the given IP
     */
    private fun checkPtpIpPort(ip: String): Boolean {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress(ip, PTPIP_PORT), SOCKET_TIMEOUT)
                log("DEBUG", "PTP/IP port open on $ip")
                true
            }
        } catch (e: SocketTimeoutException) {
            false
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Try to get camera info via quick PTP/IP handshake
     */
    private fun getCameraInfoQuick(ip: String): Pair<String?, String?>? {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress(ip, PTPIP_PORT), SOCKET_TIMEOUT)
                socket.soTimeout = SOCKET_TIMEOUT
                
                // Send minimal init request to get camera name
                val output = socket.getOutputStream()
                val input = socket.getInputStream()
                
                // Build init command request
                val guid = ByteArray(16) { 0 }
                val hostName = "Discovery"
                val hostNameBytes = hostName.toByteArray(Charsets.UTF_16LE) + byteArrayOf(0, 0)
                val packetSize = 8 + 16 + hostNameBytes.size + 4
                
                val buffer = ByteBuffer.allocate(packetSize).order(ByteOrder.LITTLE_ENDIAN)
                buffer.putInt(packetSize)
                buffer.putInt(0x0001) // PTPIP_INIT_COMMAND_REQUEST
                buffer.put(guid)
                buffer.put(hostNameBytes)
                buffer.putInt(0x00010000)
                
                output.write(buffer.array())
                output.flush()
                
                // Read response
                val respHeader = ByteArray(8)
                if (input.read(respHeader) == 8) {
                    val respBuffer = ByteBuffer.wrap(respHeader).order(ByteOrder.LITTLE_ENDIAN)
                    val respLength = respBuffer.int
                    val respType = respBuffer.int
                    
                    if (respType == 0x0002) { // PTPIP_INIT_COMMAND_ACK
                        val remaining = ByteArray(respLength - 8)
                        input.read(remaining)
                        
                        // Parse camera name from response
                        if (remaining.size > 20) {
                            val nameBytes = remaining.copyOfRange(20, remaining.size)
                            val name = String(nameBytes, Charsets.UTF_16LE).trimEnd('\u0000')
                            return Pair(name, null)
                        }
                    }
                }
                null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Get local IP address
     */
    private fun getLocalIpAddress(): String? {
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address.hostAddress?.contains(".") == true) {
                        val ip = address.hostAddress
                        if (ip != null && !ip.startsWith("127.")) {
                            return ip
                        }
                    }
                }
            }
        } catch (e: Exception) {
            log("DEBUG", "Error getting local IP: ${e.message}")
        }
        return null
    }
    
    private fun addCamera(camera: DiscoveredCamera, onCameraFound: (DiscoveredCamera) -> Unit) {
        if (discoveredCameras.putIfAbsent(camera.ipAddress, camera) == null) {
            log("SUCCESS", "Found camera at ${camera.ipAddress}", "Method: ${camera.discoveryMethod}")
            
            // Try to get camera info
            val info = getCameraInfoQuick(camera.ipAddress)
            val updatedCamera = if (info != null) {
                camera.copy(name = info.first, manufacturer = info.second)
            } else {
                camera
            }
            discoveredCameras[camera.ipAddress] = updatedCamera
            onCameraFound(updatedCamera)
        }
    }
    
    private fun log(level: String, message: String, details: String? = null) {
        when (level) {
            "ERROR" -> Log.e(TAG, message)
            "WARNING" -> Log.w(TAG, message)
            "DEBUG" -> Log.d(TAG, message)
            else -> Log.i(TAG, message)
        }
        logger(level, message, details)
    }
}
