import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../models/connection_status.dart';
import '../models/log_entry.dart';
import '../models/camera_image.dart';
import '../models/discovered_camera.dart';

/// Camera service for PTP/IP communication via platform channels
class CameraService {
  static const MethodChannel _channel = MethodChannel('com.tanzo.camera/ptp');
  static const EventChannel _eventChannel = EventChannel(
    'com.tanzo.camera/ptp_events',
  );

  // Stream controllers
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<CameraImage>> _imagesController =
      StreamController<List<CameraImage>>.broadcast();

  // Public streams
  Stream<LogEntry> get logStream => _logController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<List<CameraImage>> get imagesStream => _imagesController.stream;

  // State
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;
  ConnectionStatus get currentStatus => _currentStatus;

  String? _connectedCameraName;
  String? get connectedCameraName => _connectedCameraName;

  String? _connectedIpAddress;
  String? get connectedIpAddress => _connectedIpAddress;

  StreamSubscription? _eventSubscription;

  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;

  CameraService._internal() {
    _setupEventChannel();
  }

  /// Setup event channel for receiving updates from native side
  void _setupEventChannel() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final type = event['type'];
          switch (type) {
            case 'log':
              _logController.add(
                LogEntry.fromMap(Map<String, dynamic>.from(event)),
              );
              break;
            case 'status':
              _handleStatusUpdate(event['status']);
              break;
            case 'images':
              _handleImagesUpdate(event['images']);
              break;
            case 'progress':
              _handleProgressUpdate(event);
              break;
          }
        }
      },
      onError: (error) {
        _addLog(LogEntry.error('Event channel error: $error'));
        _updateStatus(ConnectionStatus.error);
      },
    );
  }

  void _handleStatusUpdate(String? status) {
    switch (status) {
      case 'connected':
        _updateStatus(ConnectionStatus.connected);
        break;
      case 'connecting':
        _updateStatus(ConnectionStatus.connecting);
        break;
      case 'disconnected':
        _updateStatus(ConnectionStatus.disconnected);
        break;
      case 'error':
        _updateStatus(ConnectionStatus.error);
        break;
    }
  }

  void _handleImagesUpdate(dynamic images) {
    if (images is List) {
      final cameraImages = images
          .map((e) => CameraImage.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _imagesController.add(cameraImages);
    }
  }

  void _handleProgressUpdate(Map event) {
    final current = event['current'] ?? 0;
    final total = event['total'] ?? 0;
    final message = event['message'] ?? 'Processing...';
    _addLog(LogEntry.debug('$message ($current/$total)'));
  }

  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _addLog(LogEntry entry) {
    _logController.add(entry);
  }

  /// Connect to camera via PTP/IP
  Future<bool> connect(String ipAddress, {int port = 15740}) async {
    try {
      _updateStatus(ConnectionStatus.connecting);
      _addLog(LogEntry.info('Initiating connection to $ipAddress:$port'));

      final result = await _channel.invokeMethod<Map>('connect', {
        'ipAddress': ipAddress,
        'port': port,
      });

      if (result?['success'] == true) {
        _connectedCameraName = result?['cameraName'];
        _connectedIpAddress = ipAddress;
        _updateStatus(ConnectionStatus.connected);
        _addLog(LogEntry.success('Connected to camera', _connectedCameraName));
        return true;
      } else {
        _updateStatus(ConnectionStatus.error);
        _addLog(LogEntry.error('Connection failed', result?['error']));
        return false;
      }
    } on PlatformException catch (e) {
      _updateStatus(ConnectionStatus.error);
      _addLog(
        LogEntry.error('Platform error: ${e.message}', e.details?.toString()),
      );
      return false;
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      _addLog(LogEntry.error('Unexpected error', e.toString()));
      return false;
    }
  }

  /// Auto-discover and connect to camera
  Future<bool> autoConnect() async {
    try {
      _updateStatus(ConnectionStatus.connecting);
      _addLog(LogEntry.info('Starting auto-discovery...'));

      final result = await _channel.invokeMethod<Map>('autoConnect');

      if (result?['success'] == true) {
        _connectedCameraName = result?['cameraName'];
        _connectedIpAddress = result?['ipAddress'];
        _updateStatus(ConnectionStatus.connected);
        _addLog(
          LogEntry.success(
            'Auto-connected to camera',
            '${_connectedCameraName} at ${_connectedIpAddress}',
          ),
        );
        return true;
      } else {
        _updateStatus(ConnectionStatus.error);
        _addLog(LogEntry.error('Auto-connect failed', result?['error']));
        return false;
      }
    } on PlatformException catch (e) {
      _updateStatus(ConnectionStatus.error);
      _addLog(LogEntry.error('Auto-connect error: ${e.message}'));
      return false;
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      _addLog(LogEntry.error('Unexpected error', e.toString()));
      return false;
    }
  }

  /// Discover cameras on the network
  Future<List<DiscoveredCamera>> discoverCameras() async {
    try {
      _addLog(LogEntry.info('Discovering cameras...'));

      final result = await _channel.invokeMethod<Map>('discoverCameras');

      if (result?['success'] == true) {
        final cameras =
            (result?['cameras'] as List?)
                ?.map(
                  (e) => DiscoveredCamera.fromMap(Map<String, dynamic>.from(e)),
                )
                .toList() ??
            [];
        _addLog(LogEntry.success('Found ${cameras.length} camera(s)'));
        return cameras;
      } else {
        _addLog(
          LogEntry.warning('Discovery completed with issues', result?['error']),
        );
        return [];
      }
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Discovery error: ${e.message}'));
      return [];
    }
  }

  /// Disconnect from camera
  Future<void> disconnect() async {
    try {
      _addLog(LogEntry.info('Disconnecting from camera'));
      await _channel.invokeMethod('disconnect');
      _updateStatus(ConnectionStatus.disconnected);
      _connectedCameraName = null;
      _connectedIpAddress = null;
      _addLog(LogEntry.success('Disconnected'));
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Disconnect error: ${e.message}'));
    }
  }

  /// Get list of images on camera
  Future<List<CameraImage>> getImages() async {
    try {
      _addLog(LogEntry.info('Fetching image list from camera'));
      final result = await _channel.invokeMethod<List>('getImages');

      if (result != null) {
        final images = result
            .map((e) => CameraImage.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _addLog(LogEntry.success('Found ${images.length} images'));
        _imagesController.add(images);
        return images;
      }
      return [];
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Failed to get images: ${e.message}'));
      return [];
    }
  }

  /// Download specific image by handle
  Future<Uint8List?> downloadImage(String objectHandle) async {
    try {
      _addLog(LogEntry.info('Downloading image: $objectHandle'));
      final result = await _channel.invokeMethod<String>('downloadImage', {
        'objectHandle': objectHandle,
      });

      if (result != null) {
        _addLog(LogEntry.success('Image downloaded successfully'));
        return base64Decode(result);
      }
      return null;
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Download failed: ${e.message}'));
      return null;
    }
  }

  /// Download thumbnail for an image
  Future<Uint8List?> downloadThumbnail(String objectHandle) async {
    try {
      final result = await _channel.invokeMethod<String>('downloadThumbnail', {
        'objectHandle': objectHandle,
      });

      if (result != null) {
        return base64Decode(result);
      }
      return null;
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Thumbnail download failed: ${e.message}'));
      return null;
    }
  }

  /// Get camera device info
  Future<Map<String, dynamic>?> getCameraInfo() async {
    try {
      _addLog(LogEntry.info('Getting camera information'));
      final result = await _channel.invokeMethod<Map>('getCameraInfo');
      if (result != null) {
        final info = Map<String, dynamic>.from(result);
        _addLog(LogEntry.success('Camera info retrieved', jsonEncode(info)));
        return info;
      }
      return null;
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Failed to get camera info: ${e.message}'));
      return null;
    }
  }

  /// Get storage info from camera
  Future<Map<String, dynamic>?> getStorageInfo() async {
    try {
      _addLog(LogEntry.info('Getting storage information'));
      final result = await _channel.invokeMethod<Map>('getStorageInfo');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      _addLog(LogEntry.error('Failed to get storage info: ${e.message}'));
      return null;
    }
  }

  /// Clear all logs
  void clearLogs() {
    _addLog(LogEntry.info('Logs cleared'));
  }

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _logController.close();
    _statusController.close();
    _imagesController.close();
  }
}
