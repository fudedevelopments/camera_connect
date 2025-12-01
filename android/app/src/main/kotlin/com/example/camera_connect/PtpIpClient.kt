package com.example.camera_connect

import android.util.Log
import java.io.*
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * PTP/IP Client for camera communication
 * Implements PTP/IP protocol for connecting to cameras over WiFi
 */
class PtpIpClient(
    private val ipAddress: String,
    private val port: Int = 15740,
    private val logger: (String, String, String?) -> Unit = { _, _, _ -> }
) {
    companion object {
        private const val TAG = "PtpIpClient"
        
        // PTP/IP Packet Types
        private const val PTPIP_INIT_COMMAND_REQUEST = 0x0001
        private const val PTPIP_INIT_COMMAND_ACK = 0x0002
        private const val PTPIP_INIT_EVENT_REQUEST = 0x0003
        private const val PTPIP_INIT_EVENT_ACK = 0x0004
        private const val PTPIP_CMD_REQUEST = 0x0006
        private const val PTPIP_CMD_RESPONSE = 0x0007
        private const val PTPIP_EVENT = 0x0008
        private const val PTPIP_START_DATA_PACKET = 0x0009
        private const val PTPIP_DATA_PACKET = 0x000A
        private const val PTPIP_END_DATA_PACKET = 0x000C
        
        // PTP Operation Codes
        private const val PTP_OC_GetDeviceInfo = 0x1001
        private const val PTP_OC_OpenSession = 0x1002
        private const val PTP_OC_CloseSession = 0x1003
        private const val PTP_OC_GetStorageIDs = 0x1004
        private const val PTP_OC_GetStorageInfo = 0x1005
        private const val PTP_OC_GetNumObjects = 0x1006
        private const val PTP_OC_GetObjectHandles = 0x1007
        private const val PTP_OC_GetObjectInfo = 0x1008
        private const val PTP_OC_GetObject = 0x1009
        private const val PTP_OC_GetThumb = 0x100A
        
        // PTP Response Codes
        private const val PTP_RC_OK = 0x2001
        private const val PTP_RC_SessionNotOpen = 0x2003
        private const val PTP_RC_InvalidTransactionID = 0x2004
        
        // Connection timeouts
        private const val CONNECT_TIMEOUT = 10000
        private const val READ_TIMEOUT = 30000
    }
    
    private var commandSocket: Socket? = null
    private var eventSocket: Socket? = null
    private var commandInput: DataInputStream? = null
    private var commandOutput: DataOutputStream? = null
    private var eventInput: DataInputStream? = null
    private var eventOutput: DataOutputStream? = null
    
    private var sessionId: Int = 0
    private var transactionId: Int = 0
    private var connectionNumber: Int = 0
    private var deviceInfo: DeviceInfo? = null
    
    private val guid = generateGuid()
    private val hostName = "CameraConnect"
    
    /**
     * Connect to camera
     */
    fun connect(): Boolean {
        try {
            log("INFO", "Opening command socket to $ipAddress:$port")
            log("DEBUG", "Port value: $port (type: ${port.javaClass.name})")
            
            if (port <= 0 || port > 65535) {
                log("ERROR", "Invalid port number: $port")
                return false
            }
            
            // Connect command socket
            val socketAddress = InetSocketAddress(ipAddress, port)
            log("DEBUG", "Socket address: ${socketAddress.hostString}:${socketAddress.port}")
            
            commandSocket = Socket().apply {
                soTimeout = READ_TIMEOUT
                connect(socketAddress, CONNECT_TIMEOUT)
            }
            
            commandInput = DataInputStream(BufferedInputStream(commandSocket!!.getInputStream()))
            commandOutput = DataOutputStream(BufferedOutputStream(commandSocket!!.getOutputStream()))
            
            log("DEBUG", "Command socket connected")
            
            // Send Init Command Request
            if (!sendInitCommandRequest()) {
                log("ERROR", "Init command request failed")
                return false
            }
            
            log("DEBUG", "Init command request successful")
            
            // Try to connect event socket (optional for some cameras)
            val eventConnected = tryConnectEventSocket()
            if (!eventConnected) {
                log("WARNING", "Event socket not available, continuing without events")
                // Some cameras work fine without event socket
            }
            
            // Open session
            if (!openSession()) {
                log("ERROR", "Failed to open session")
                return false
            }
            
            log("SUCCESS", "Session opened successfully")
            
            // Get device info
            deviceInfo = fetchDeviceInfo()
            log("INFO", "Device: ${deviceInfo?.model ?: "Unknown"}")
            
            return true
            
        } catch (e: Exception) {
            Log.e(TAG, "Connection failed", e)
            log("ERROR", "Connection failed: ${e.message}", e.stackTraceToString())
            disconnect()
            return false
        }
    }
    
    /**
     * Try to connect event socket - optional for some cameras
     */
    private fun tryConnectEventSocket(): Boolean {
        // Try different event port strategies
        val eventPorts = listOf(port, port + 1, 15741, 15742)
        
        for (eventPort in eventPorts.distinct()) {
            try {
                log("DEBUG", "Trying event socket on port $eventPort")
                
                eventSocket = Socket().apply {
                    soTimeout = 3000 // Shorter timeout for event socket attempts
                    connect(InetSocketAddress(ipAddress, eventPort), 3000)
                }
                
                eventInput = DataInputStream(BufferedInputStream(eventSocket!!.getInputStream()))
                eventOutput = DataOutputStream(BufferedOutputStream(eventSocket!!.getOutputStream()))
                
                // Send Init Event Request
                if (sendInitEventRequest()) {
                    log("SUCCESS", "Event socket connected on port $eventPort")
                    return true
                } else {
                    eventSocket?.close()
                    eventSocket = null
                }
            } catch (e: Exception) {
                log("DEBUG", "Event socket on port $eventPort failed: ${e.message}")
                eventSocket?.close()
                eventSocket = null
            }
        }
        
        return false
    }
    
    /**
     * Disconnect from camera
     */
    fun disconnect() {
        try {
            if (sessionId != 0) {
                closeSession()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error closing session", e)
        }
        
        try {
            commandSocket?.close()
            eventSocket?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing sockets", e)
        }
        
        commandSocket = null
        eventSocket = null
        commandInput = null
        commandOutput = null
        eventInput = null
        eventOutput = null
        sessionId = 0
        transactionId = 0
        deviceInfo = null
        
        log("INFO", "Disconnected")
    }
    
    /**
     * Get camera name
     */
    fun getCameraName(): String {
        return deviceInfo?.model ?: "Unknown Camera"
    }
    
    /**
     * Get device info
     */
    fun getDeviceInfo(): DeviceInfo? {
        return deviceInfo
    }
    
    /**
     * Get storage IDs
     */
    fun getStorageIds(): List<Int> {
        val response = sendCommand(PTP_OC_GetStorageIDs)
        if (response.responseCode != PTP_RC_OK) {
            log("ERROR", "Failed to get storage IDs: ${response.responseCode}")
            return emptyList()
        }
        
        val data = response.data ?: return emptyList()
        val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        val count = buffer.int
        
        return (0 until count).map { buffer.int }
    }
    
    /**
     * Get storage info for a specific storage ID
     */
    fun getStorageInfo(storageId: Int): StorageInfo? {
        val response = sendCommand(PTP_OC_GetStorageInfo, storageId)
        if (response.responseCode != PTP_RC_OK) {
            return null
        }
        
        val data = response.data ?: return null
        return parseStorageInfo(data)
    }
    
    /**
     * Get object handles (list of images)
     */
    fun getObjectHandles(storageId: Int = 0xFFFFFFFF.toInt()): List<Long> {
        log("DEBUG", "Getting object handles for storage: $storageId")
        
        val response = sendCommand(
            PTP_OC_GetObjectHandles,
            storageId,
            0x00000000, // All formats
            0x00000000  // All associations
        )
        
        if (response.responseCode != PTP_RC_OK) {
            log("ERROR", "Failed to get object handles: ${response.responseCode}")
            return emptyList()
        }
        
        val data = response.data ?: return emptyList()
        val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        val count = buffer.int
        
        log("DEBUG", "Found $count objects")
        
        return (0 until count).map { buffer.int.toLong() and 0xFFFFFFFFL }
    }
    
    /**
     * Get object info
     */
    fun getObjectInfo(objectHandle: Long): ObjectInfo? {
        val response = sendCommand(PTP_OC_GetObjectInfo, objectHandle.toInt())
        if (response.responseCode != PTP_RC_OK) {
            return null
        }
        
        val data = response.data ?: return null
        return parseObjectInfo(data)
    }
    
    /**
     * Get full object (image data)
     */
    fun getObject(objectHandle: Long): ByteArray? {
        log("INFO", "Downloading object: $objectHandle")
        
        val response = sendCommand(PTP_OC_GetObject, objectHandle.toInt())
        if (response.responseCode != PTP_RC_OK) {
            log("ERROR", "Failed to get object: ${response.responseCode}")
            return null
        }
        
        return response.data
    }
    
    /**
     * Get thumbnail
     */
    fun getThumb(objectHandle: Long): ByteArray? {
        val response = sendCommand(PTP_OC_GetThumb, objectHandle.toInt())
        if (response.responseCode != PTP_RC_OK) {
            return null
        }
        
        return response.data
    }
    
    // ==================== Private Methods ====================
    
    private fun sendInitCommandRequest(): Boolean {
        log("DEBUG", "Sending init command request")
        
        // Build init command request packet
        val hostNameBytes = hostName.toByteArray(Charsets.UTF_16LE)
        val hostNameWithNull = hostNameBytes + byteArrayOf(0, 0)
        
        val packetSize = 8 + 16 + hostNameWithNull.size + 4 // header + GUID + hostname + version
        val buffer = ByteBuffer.allocate(packetSize).order(ByteOrder.LITTLE_ENDIAN)
        
        buffer.putInt(packetSize) // Length
        buffer.putInt(PTPIP_INIT_COMMAND_REQUEST) // Type
        buffer.put(guid) // GUID (16 bytes)
        buffer.put(hostNameWithNull) // Hostname (UTF-16LE null terminated)
        buffer.putInt(0x00010000) // Protocol version 1.0
        
        commandOutput?.write(buffer.array())
        commandOutput?.flush()
        
        // Read response
        val respLength = readIntLE(commandInput!!)
        val respType = readIntLE(commandInput!!)
        
        log("DEBUG", "Init response: length=$respLength, type=$respType")
        
        if (respType != PTPIP_INIT_COMMAND_ACK) {
            log("ERROR", "Unexpected response type: $respType")
            return false
        }
        
        // Read connection number and GUID
        connectionNumber = readIntLE(commandInput!!)
        val cameraGuid = ByteArray(16)
        commandInput?.readFully(cameraGuid)
        
        // Read remaining response (camera name, etc.)
        val remaining = respLength - 8 - 4 - 16
        if (remaining > 0) {
            val cameraNameBytes = ByteArray(remaining)
            commandInput?.readFully(cameraNameBytes)
            val cameraName = String(cameraNameBytes, Charsets.UTF_16LE).trimEnd('\u0000')
            log("DEBUG", "Camera name: $cameraName")
        }
        
        log("DEBUG", "Connection number: $connectionNumber")
        return true
    }
    
    private fun sendInitEventRequest(): Boolean {
        log("DEBUG", "Sending init event request")
        
        val packetSize = 8 + 4 // header + connection number
        val buffer = ByteBuffer.allocate(packetSize).order(ByteOrder.LITTLE_ENDIAN)
        
        buffer.putInt(packetSize)
        buffer.putInt(PTPIP_INIT_EVENT_REQUEST)
        buffer.putInt(connectionNumber)
        
        eventOutput?.write(buffer.array())
        eventOutput?.flush()
        
        // Read response
        val respLength = readIntLE(eventInput!!)
        val respType = readIntLE(eventInput!!)
        
        log("DEBUG", "Event init response: length=$respLength, type=$respType")
        
        return respType == PTPIP_INIT_EVENT_ACK
    }
    
    private fun openSession(): Boolean {
        sessionId = 1
        transactionId = 0
        
        val response = sendCommand(PTP_OC_OpenSession, sessionId)
        return response.responseCode == PTP_RC_OK
    }
    
    private fun closeSession() {
        if (sessionId != 0) {
            sendCommand(PTP_OC_CloseSession)
            sessionId = 0
        }
    }
    
    private fun fetchDeviceInfo(): DeviceInfo? {
        val response = sendCommand(PTP_OC_GetDeviceInfo)
        if (response.responseCode != PTP_RC_OK) {
            return null
        }
        
        val data = response.data ?: return null
        return parseDeviceInfo(data)
    }
    
    private fun sendCommand(opCode: Int, vararg params: Int): PtpResponse {
        transactionId++
        
        // Build command packet
        val paramCount = params.size
        val packetSize = 8 + 4 + 2 + 4 + (paramCount * 4) // header + dataPhase + opCode + transId + params
        val buffer = ByteBuffer.allocate(packetSize).order(ByteOrder.LITTLE_ENDIAN)
        
        buffer.putInt(packetSize)
        buffer.putInt(PTPIP_CMD_REQUEST)
        buffer.putInt(1) // Data phase info
        buffer.putShort(opCode.toShort())
        buffer.putInt(transactionId)
        
        for (param in params) {
            buffer.putInt(param)
        }
        
        try {
            commandOutput?.write(buffer.array())
            commandOutput?.flush()
            
            return readResponse()
        } catch (e: Exception) {
            Log.e(TAG, "Command failed", e)
            return PtpResponse(0, null)
        }
    }
    
    private fun readResponse(): PtpResponse {
        var responseCode = 0
        var data: ByteArray? = null
        val dataBuffer = ByteArrayOutputStream()
        
        while (true) {
            val packetLength = readIntLE(commandInput!!)
            val packetType = readIntLE(commandInput!!)
            
            when (packetType) {
                PTPIP_START_DATA_PACKET -> {
                    val respTransId = readIntLE(commandInput!!)
                    val totalDataLength = readLongLE(commandInput!!)
                    log("DEBUG", "Start data packet: transId=$respTransId, totalLength=$totalDataLength")
                }
                
                PTPIP_DATA_PACKET -> {
                    val respTransId = readIntLE(commandInput!!)
                    val payloadLength = packetLength - 12
                    val payload = ByteArray(payloadLength)
                    commandInput?.readFully(payload)
                    dataBuffer.write(payload)
                }
                
                PTPIP_END_DATA_PACKET -> {
                    val respTransId = readIntLE(commandInput!!)
                    val payloadLength = packetLength - 12
                    if (payloadLength > 0) {
                        val payload = ByteArray(payloadLength)
                        commandInput?.readFully(payload)
                        dataBuffer.write(payload)
                    }
                    data = dataBuffer.toByteArray()
                }
                
                PTPIP_CMD_RESPONSE -> {
                    responseCode = readShortLE(commandInput!!).toInt() and 0xFFFF
                    val respTransId = readIntLE(commandInput!!)
                    
                    // Read any parameters
                    val paramBytes = packetLength - 14
                    if (paramBytes > 0) {
                        val params = ByteArray(paramBytes)
                        commandInput?.readFully(params)
                    }
                    
                    if (data == null && dataBuffer.size() > 0) {
                        data = dataBuffer.toByteArray()
                    }
                    
                    return PtpResponse(responseCode, data)
                }
                
                else -> {
                    log("WARNING", "Unknown packet type: $packetType")
                    // Skip remaining bytes
                    val remaining = packetLength - 8
                    if (remaining > 0) {
                        commandInput?.skipBytes(remaining)
                    }
                }
            }
        }
    }
    
    // ==================== Parser Methods ====================
    
    private fun parseDeviceInfo(data: ByteArray): DeviceInfo {
        val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        
        val standardVersion = buffer.short
        val vendorExtensionId = buffer.int
        val vendorExtensionVersion = buffer.short
        val vendorExtensionDesc = readPtpString(buffer)
        val functionalMode = buffer.short
        
        val operationsSupported = readPtpArray(buffer)
        val eventsSupported = readPtpArray(buffer)
        val devicePropertiesSupported = readPtpArray(buffer)
        val captureFormats = readPtpArray(buffer)
        val imageFormats = readPtpArray(buffer)
        
        val manufacturer = readPtpString(buffer)
        val model = readPtpString(buffer)
        val deviceVersion = readPtpString(buffer)
        val serialNumber = readPtpString(buffer)
        
        return DeviceInfo(
            standardVersion = standardVersion.toInt(),
            vendorExtensionId = vendorExtensionId,
            vendorExtensionVersion = vendorExtensionVersion.toInt(),
            vendorExtensionDesc = vendorExtensionDesc,
            functionalMode = functionalMode.toInt(),
            manufacturer = manufacturer,
            model = model,
            deviceVersion = deviceVersion,
            serialNumber = serialNumber
        )
    }
    
    private fun parseStorageInfo(data: ByteArray): StorageInfo {
        val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        
        val storageType = buffer.short.toInt()
        val filesystemType = buffer.short.toInt()
        val accessCapability = buffer.short.toInt()
        val maxCapacity = buffer.long
        val freeSpaceInBytes = buffer.long
        val freeSpaceInImages = buffer.int
        val storageDescription = readPtpString(buffer)
        val volumeLabel = readPtpString(buffer)
        
        return StorageInfo(
            storageType = storageType,
            filesystemType = filesystemType,
            accessCapability = accessCapability,
            maxCapacity = maxCapacity,
            freeSpaceInBytes = freeSpaceInBytes,
            freeSpaceInImages = freeSpaceInImages,
            storageDescription = storageDescription,
            volumeLabel = volumeLabel
        )
    }
    
    private fun parseObjectInfo(data: ByteArray): ObjectInfo {
        val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        
        val storageId = buffer.int
        val objectFormat = buffer.short.toInt() and 0xFFFF
        val protectionStatus = buffer.short.toInt()
        val objectCompressedSize = buffer.int
        val thumbFormat = buffer.short.toInt()
        val thumbCompressedSize = buffer.int
        val thumbPixWidth = buffer.int
        val thumbPixHeight = buffer.int
        val imagePixWidth = buffer.int
        val imagePixHeight = buffer.int
        val imageBitDepth = buffer.int
        val parentObject = buffer.int
        val associationType = buffer.short.toInt()
        val associationDesc = buffer.int
        val sequenceNumber = buffer.int
        val filename = readPtpString(buffer)
        val captureDate = readPtpString(buffer)
        val modificationDate = readPtpString(buffer)
        val keywords = readPtpString(buffer)
        
        return ObjectInfo(
            storageId = storageId,
            objectFormat = objectFormat,
            protectionStatus = protectionStatus,
            objectCompressedSize = objectCompressedSize,
            thumbFormat = thumbFormat,
            thumbCompressedSize = thumbCompressedSize,
            thumbPixWidth = thumbPixWidth,
            thumbPixHeight = thumbPixHeight,
            imageWidth = imagePixWidth,
            imageHeight = imagePixHeight,
            imageBitDepth = imageBitDepth,
            parentObject = parentObject,
            associationType = associationType,
            associationDesc = associationDesc,
            sequenceNumber = sequenceNumber,
            filename = filename,
            captureDate = captureDate,
            modificationDate = modificationDate,
            keywords = keywords,
            formatName = getFormatName(objectFormat)
        )
    }
    
    private fun readPtpString(buffer: ByteBuffer): String {
        val numChars = buffer.get().toInt() and 0xFF
        if (numChars == 0) return ""
        
        val chars = CharArray(numChars - 1)
        for (i in 0 until numChars - 1) {
            chars[i] = buffer.short.toInt().toChar()
        }
        buffer.short // Null terminator
        
        return String(chars)
    }
    
    private fun readPtpArray(buffer: ByteBuffer): List<Int> {
        val count = buffer.int
        return (0 until count).map { buffer.short.toInt() and 0xFFFF }
    }
    
    private fun getFormatName(format: Int): String {
        return when (format) {
            0x3000 -> "Undefined"
            0x3001 -> "Association"
            0x3002 -> "Script"
            0x3006 -> "DPOF"
            0x3800 -> "JPEG"
            0x3801 -> "TIFF-EP"
            0x3802 -> "FlashPix"
            0x3803 -> "BMP"
            0x3804 -> "CIFF"
            0x3807 -> "GIF"
            0x3808 -> "JFIF"
            0x380B -> "PNG"
            0x380D -> "TIFF"
            0x3811 -> "JP2"
            0x3812 -> "JPX"
            0xB101 -> "RAW"
            0xB103 -> "CR2"
            0xB104 -> "CR3"
            0xB108 -> "NEF"
            else -> "Format_${String.format("%04X", format)}"
        }
    }
    
    // ==================== Utility Methods ====================
    
    private fun readIntLE(input: DataInputStream): Int {
        val bytes = ByteArray(4)
        input.readFully(bytes)
        return ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).int
    }
    
    private fun readShortLE(input: DataInputStream): Short {
        val bytes = ByteArray(2)
        input.readFully(bytes)
        return ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).short
    }
    
    private fun readLongLE(input: DataInputStream): Long {
        val bytes = ByteArray(8)
        input.readFully(bytes)
        return ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).long
    }
    
    private fun generateGuid(): ByteArray {
        return ByteArray(16) { (Math.random() * 256).toInt().toByte() }
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

/**
 * PTP Response wrapper
 */
data class PtpResponse(
    val responseCode: Int,
    val data: ByteArray?
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as PtpResponse
        if (responseCode != other.responseCode) return false
        if (data != null) {
            if (other.data == null) return false
            if (!data.contentEquals(other.data)) return false
        } else if (other.data != null) return false
        return true
    }

    override fun hashCode(): Int {
        var result = responseCode
        result = 31 * result + (data?.contentHashCode() ?: 0)
        return result
    }
}

/**
 * Device Info model
 */
data class DeviceInfo(
    val standardVersion: Int,
    val vendorExtensionId: Int,
    val vendorExtensionVersion: Int,
    val vendorExtensionDesc: String,
    val functionalMode: Int,
    val manufacturer: String,
    val model: String,
    val deviceVersion: String,
    val serialNumber: String
)

/**
 * Storage Info model
 */
data class StorageInfo(
    val storageType: Int,
    val filesystemType: Int,
    val accessCapability: Int,
    val maxCapacity: Long,
    val freeSpaceInBytes: Long,
    val freeSpaceInImages: Int,
    val storageDescription: String,
    val volumeLabel: String
)

/**
 * Object Info model
 */
data class ObjectInfo(
    val storageId: Int,
    val objectFormat: Int,
    val protectionStatus: Int,
    val objectCompressedSize: Int,
    val thumbFormat: Int,
    val thumbCompressedSize: Int,
    val thumbPixWidth: Int,
    val thumbPixHeight: Int,
    val imageWidth: Int,
    val imageHeight: Int,
    val imageBitDepth: Int,
    val parentObject: Int,
    val associationType: Int,
    val associationDesc: Int,
    val sequenceNumber: Int,
    val filename: String,
    val captureDate: String,
    val modificationDate: String,
    val keywords: String,
    val formatName: String
)
