import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' as flutter_services;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/connection_status.dart';
import '../models/camera_model.dart';
import '../models/image_model.dart';
import '../models/log_entry_model.dart';

/// Remote data source for camera operations via platform channels
abstract class CameraRemoteDataSource {
  /// Discover cameras on the network
  Future<List<CameraModel>> discoverCameras();

  /// Connect to a specific camera
  Future<void> connectToCamera(String ipAddress, int port);

  /// Disconnect from current camera
  Future<void> disconnect();

  /// Get connection status stream
  Stream<ConnectionStatus> getConnectionStatusStream();

  /// Get camera images
  Future<List<ImageModel>> getCameraImages();

  /// Download full image data
  Future<ImageModel> downloadImage(String objectHandle);

  /// Get log entries stream
  Stream<LogEntryModel> getLogStream();

  /// Get images stream
  Stream<List<ImageModel>> getImagesStream();
}

class CameraRemoteDataSourceImpl implements CameraRemoteDataSource {
  static const flutter_services.MethodChannel _channel =
      flutter_services.MethodChannel(AppConstants.ptpMethodChannel);
  static const flutter_services.EventChannel _eventChannel =
      flutter_services.EventChannel(AppConstants.ptpEventChannel);

  // Stream controllers
  final StreamController<LogEntryModel> _logController =
      StreamController<LogEntryModel>.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<ImageModel>> _imagesController =
      StreamController<List<ImageModel>>.broadcast();

  StreamSubscription? _eventSubscription;

  CameraRemoteDataSourceImpl() {
    _setupEventChannel();
  }

  void _setupEventChannel() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final type = event['type'];
          switch (type) {
            case AppConstants.eventTypeLog:
              _logController.add(
                LogEntryModel.fromMap(Map<String, dynamic>.from(event)),
              );
              break;
            case AppConstants.eventTypeStatus:
              _handleStatusUpdate(event['status']);
              break;
            case AppConstants.eventTypeImages:
              _handleImagesUpdate(event['images']);
              break;
          }
        }
      },
      onError: (error) {
        _statusController.add(ConnectionStatus.error);
      },
    );
  }

  void _handleStatusUpdate(String? status) {
    switch (status) {
      case 'connected':
        _statusController.add(ConnectionStatus.connected);
        break;
      case 'connecting':
        _statusController.add(ConnectionStatus.connecting);
        break;
      case 'disconnected':
        _statusController.add(ConnectionStatus.disconnected);
        break;
      case 'error':
        _statusController.add(ConnectionStatus.error);
        break;
    }
  }

  void _handleImagesUpdate(dynamic images) {
    if (images is List) {
      final cameraImages = images
          .map((e) => ImageModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _imagesController.add(cameraImages);
    }
  }

  @override
  Future<List<CameraModel>> discoverCameras() async {
    try {
      final result = await _channel.invokeMethod<Map>('discoverCameras');

      if (result?['success'] == true) {
        final cameras =
            (result?['cameras'] as List?)
                ?.map((e) => CameraModel.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        return cameras;
      } else {
        throw CameraException(
          message: 'Failed to discover cameras',
          details: result?['error'],
        );
      }
    } on flutter_services.PlatformException catch (e) {
      throw PlatformChannelException(
        message: 'Platform error during discovery',
        details: e.message,
      );
    }
  }

  @override
  Future<void> connectToCamera(String ipAddress, int port) async {
    try {
      final result = await _channel.invokeMethod<Map>('connect', {
        'ipAddress': ipAddress,
        'port': port,
      });

      if (result?['success'] != true) {
        throw ConnectionException(
          message: 'Failed to connect to camera',
          details: result?['error'],
        );
      }
    } on flutter_services.PlatformException catch (e) {
      throw PlatformChannelException(
        message: 'Platform error during connection',
        details: e.message,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformChannelException(
        message: 'Platform error during disconnect',
        details: e.message,
      );
    }
  }

  @override
  Stream<ConnectionStatus> getConnectionStatusStream() {
    return _statusController.stream;
  }

  @override
  Future<List<ImageModel>> getCameraImages() async {
    try {
      final result = await _channel.invokeMethod<List>('getImages');

      if (result != null) {
        final images = result
            .map((e) => ImageModel.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return images;
      }
      return [];
    } on flutter_services.PlatformException catch (e) {
      throw PlatformChannelException(
        message: 'Failed to get images',
        details: e.message,
      );
    }
  }

  @override
  Future<ImageModel> downloadImage(String objectHandle) async {
    try {
      final result = await _channel.invokeMethod<String>('downloadImage', {
        'objectHandle': objectHandle,
      });

      if (result != null) {
        final imageData = base64Decode(result);
        // Create image model with downloaded data
        return ImageModel(
          objectHandle: objectHandle,
          filename: 'downloaded_$objectHandle',
          size: imageData.length,
          format: 'JPEG',
          imageData: imageData,
        );
      }
      throw CameraException(message: 'Failed to download image');
    } on flutter_services.PlatformException catch (e) {
      throw PlatformChannelException(
        message: 'Download failed',
        details: e.message,
      );
    }
  }

  @override
  Stream<LogEntryModel> getLogStream() {
    return _logController.stream;
  }

  @override
  Stream<List<ImageModel>> getImagesStream() {
    return _imagesController.stream;
  }

  void dispose() {
    _eventSubscription?.cancel();
    _logController.close();
    _statusController.close();
    _imagesController.close();
  }
}
