package com.example.camera_connect

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "CameraConnect"
        private const val METHOD_CHANNEL = "com.tanzo.camera/ptp"
        private const val EVENT_CHANNEL = "com.tanzo.camera/ptp_events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    
    private var ptpClient: PtpIpClient? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Method Channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "connect" -> handleConnect(call.arguments as? Map<*, *>, result)
                "disconnect" -> handleDisconnect(result)
                "getImages" -> handleGetImages(result)
                "downloadImage" -> handleDownloadImage(call.arguments as? Map<*, *>, result)
                "downloadThumbnail" -> handleDownloadThumbnail(call.arguments as? Map<*, *>, result)
                "getCameraInfo" -> handleGetCameraInfo(result)
                "getStorageInfo" -> handleGetStorageInfo(result)
                else -> result.notImplemented()
            }
        }

        // Setup Event Channel
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                sendLog("INFO", "Event channel connected")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun handleConnect(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val ipAddress = arguments?.get("ipAddress") as? String
        
        // Handle port - can come as Int, Long, or Double from Flutter
        val portArg = arguments?.get("port")
        val port: Int = when (portArg) {
            is Int -> portArg
            is Long -> portArg.toInt()
            is Double -> portArg.toInt()
            is Number -> portArg.toInt()
            else -> 15740
        }

        sendLog("DEBUG", "Received args: ip=$ipAddress, port=$port, portArg=$portArg (${portArg?.javaClass?.name})")

        if (ipAddress.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "IP address is required", null)
            return
        }

        if (port <= 0 || port > 65535) {
            result.error("INVALID_ARGS", "Invalid port: $port", null)
            return
        }

        sendLog("INFO", "Connecting to $ipAddress:$port")
        sendStatus("connecting")

        coroutineScope.launch {
            try {
                ptpClient = PtpIpClient(
                    ipAddress = ipAddress,
                    port = port,
                    logger = { level, message, details ->
                        sendLog(level, message, details)
                    }
                )

                val connected = ptpClient?.connect() ?: false
                
                if (connected) {
                    val cameraName = ptpClient?.getCameraName() ?: "Unknown Camera"
                    
                    mainHandler.post {
                        sendStatus("connected")
                        sendLog("SUCCESS", "Connected to camera", cameraName)
                        result.success(mapOf(
                            "success" to true,
                            "cameraName" to cameraName
                        ))
                    }
                } else {
                    mainHandler.post {
                        sendStatus("error")
                        sendLog("ERROR", "Connection failed")
                        result.success(mapOf(
                            "success" to false,
                            "error" to "Failed to establish connection"
                        ))
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Connection error", e)
                mainHandler.post {
                    sendStatus("error")
                    sendLog("ERROR", "Connection error: ${e.message}", e.stackTraceToString())
                    result.success(mapOf(
                        "success" to false,
                        "error" to e.message
                    ))
                }
            }
        }
    }

    private fun handleDisconnect(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                ptpClient?.disconnect()
                ptpClient = null
                
                mainHandler.post {
                    sendStatus("disconnected")
                    sendLog("SUCCESS", "Disconnected from camera")
                    result.success(null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Disconnect error", e)
                mainHandler.post {
                    sendLog("ERROR", "Disconnect error: ${e.message}")
                    result.error("DISCONNECT_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleGetImages(result: MethodChannel.Result) {
        if (ptpClient == null) {
            result.error("NOT_CONNECTED", "Not connected to camera", null)
            return
        }

        sendLog("INFO", "Fetching image list...")

        coroutineScope.launch {
            try {
                val images = ptpClient?.getObjectHandles() ?: emptyList()
                
                val imageList = images.mapIndexed { index, handle ->
                    // Get object info for each handle
                    val info = ptpClient?.getObjectInfo(handle)
                    
                    sendLog("DEBUG", "Processing image ${index + 1}/${images.size}")
                    
                    mapOf(
                        "objectHandle" to handle.toString(),
                        "filename" to (info?.filename ?: "IMG_${handle}.jpg"),
                        "size" to (info?.objectCompressedSize ?: 0),
                        "format" to (info?.formatName ?: "JPEG"),
                        "width" to (info?.imageWidth ?: 0),
                        "height" to (info?.imageHeight ?: 0),
                        "captureDate" to info?.captureDate
                    )
                }

                mainHandler.post {
                    sendLog("SUCCESS", "Found ${imageList.size} images")
                    result.success(imageList)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Get images error", e)
                mainHandler.post {
                    sendLog("ERROR", "Failed to get images: ${e.message}")
                    result.error("GET_IMAGES_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleDownloadImage(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val objectHandle = arguments?.get("objectHandle") as? String
        
        if (objectHandle.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "Object handle is required", null)
            return
        }

        if (ptpClient == null) {
            result.error("NOT_CONNECTED", "Not connected to camera", null)
            return
        }

        sendLog("INFO", "Downloading image: $objectHandle")

        coroutineScope.launch {
            try {
                val imageData = ptpClient?.getObject(objectHandle.toLong())
                
                if (imageData != null) {
                    val base64Data = android.util.Base64.encodeToString(
                        imageData, 
                        android.util.Base64.NO_WRAP
                    )
                    
                    mainHandler.post {
                        sendLog("SUCCESS", "Image downloaded: ${imageData.size} bytes")
                        result.success(base64Data)
                    }
                } else {
                    mainHandler.post {
                        sendLog("ERROR", "Failed to download image")
                        result.error("DOWNLOAD_ERROR", "Failed to download image", null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Download error", e)
                mainHandler.post {
                    sendLog("ERROR", "Download error: ${e.message}")
                    result.error("DOWNLOAD_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleDownloadThumbnail(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val objectHandle = arguments?.get("objectHandle") as? String
        
        if (objectHandle.isNullOrEmpty()) {
            result.error("INVALID_ARGS", "Object handle is required", null)
            return
        }

        if (ptpClient == null) {
            result.error("NOT_CONNECTED", "Not connected to camera", null)
            return
        }

        coroutineScope.launch {
            try {
                val thumbnailData = ptpClient?.getThumb(objectHandle.toLong())
                
                if (thumbnailData != null) {
                    val base64Data = android.util.Base64.encodeToString(
                        thumbnailData, 
                        android.util.Base64.NO_WRAP
                    )
                    
                    mainHandler.post {
                        result.success(base64Data)
                    }
                } else {
                    mainHandler.post {
                        result.error("DOWNLOAD_ERROR", "Failed to download thumbnail", null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Thumbnail download error", e)
                mainHandler.post {
                    result.error("DOWNLOAD_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleGetCameraInfo(result: MethodChannel.Result) {
        if (ptpClient == null) {
            result.error("NOT_CONNECTED", "Not connected to camera", null)
            return
        }

        coroutineScope.launch {
            try {
                val info = ptpClient?.getDeviceInfo()
                
                mainHandler.post {
                    if (info != null) {
                        result.success(mapOf(
                            "manufacturer" to info.manufacturer,
                            "model" to info.model,
                            "serialNumber" to info.serialNumber,
                            "firmwareVersion" to info.deviceVersion,
                            "vendorExtension" to info.vendorExtensionDesc
                        ))
                    } else {
                        result.error("GET_INFO_ERROR", "Failed to get camera info", null)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Get camera info error", e)
                mainHandler.post {
                    result.error("GET_INFO_ERROR", e.message, null)
                }
            }
        }
    }

    private fun handleGetStorageInfo(result: MethodChannel.Result) {
        if (ptpClient == null) {
            result.error("NOT_CONNECTED", "Not connected to camera", null)
            return
        }

        coroutineScope.launch {
            try {
                val storageIds = ptpClient?.getStorageIds() ?: emptyList()
                val storageInfoList = storageIds.map { id ->
                    val info = ptpClient?.getStorageInfo(id)
                    mapOf(
                        "storageId" to id,
                        "storageType" to (info?.storageType ?: 0),
                        "maxCapacity" to (info?.maxCapacity ?: 0L),
                        "freeSpace" to (info?.freeSpaceInBytes ?: 0L),
                        "description" to (info?.storageDescription ?: "")
                    )
                }
                
                mainHandler.post {
                    result.success(mapOf("storages" to storageInfoList))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Get storage info error", e)
                mainHandler.post {
                    result.error("GET_STORAGE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun sendLog(level: String, message: String, details: String? = null) {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to "log",
                "level" to level,
                "message" to message,
                "details" to details
            ))
        }
    }

    private fun sendStatus(status: String) {
        mainHandler.post {
            eventSink?.success(mapOf(
                "type" to "status",
                "status" to status
            ))
        }
    }

    override fun onDestroy() {
        coroutineScope.cancel()
        ptpClient?.disconnect()
        super.onDestroy()
    }
}
