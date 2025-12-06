import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/connect_to_camera.dart';
import '../../domain/usecases/disconnect_camera.dart';
import '../../domain/usecases/discover_cameras.dart';
import '../../domain/usecases/download_image.dart';
import '../../domain/usecases/get_camera_images.dart';
import '../../domain/usecases/get_connection_status.dart';
import 'camera_event.dart';
import 'camera_state.dart';

/// Camera BLoC
/// Handles all camera-related business logic and state management
class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final ConnectToCamera connectToCamera;
  final DisconnectCamera disconnectCamera;
  final DiscoverCameras discoverCameras;
  final GetCameraImages getCameraImages;
  final GetConnectionStatus getConnectionStatus;
  final DownloadImage downloadImage;

  StreamSubscription? _connectionStatusSubscription;
  StreamSubscription? _logStreamSubscription;
  StreamSubscription? _imagesStreamSubscription;

  CameraBloc({
    required this.connectToCamera,
    required this.disconnectCamera,
    required this.discoverCameras,
    required this.getCameraImages,
    required this.getConnectionStatus,
    required this.downloadImage,
  }) : super(CameraInitial()) {
    on<InitializeCameraEvent>(_onInitialize);
    on<DiscoverCamerasEvent>(_onDiscoverCameras);
    on<ConnectToCameraEvent>(_onConnectToCamera);
    on<DisconnectCameraEvent>(_onDisconnect);
    on<GetCameraImagesEvent>(_onGetImages);
    on<DownloadImageEvent>(_onDownloadImage);
    on<RefreshImagesEvent>(_onRefreshImages);
  }

  Future<void> _onInitialize(
    InitializeCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Set up connection status stream
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = getConnectionStatus().listen((status) {
      add(
        const ConnectToCameraEvent(ipAddress: '', port: 0),
      ); // Trigger state update
    });
  }

  Future<void> _onDiscoverCameras(
    DiscoverCamerasEvent event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());

    final result = await discoverCameras(NoParams());

    result.fold(
      (failure) =>
          emit(CameraError(message: failure.message, details: failure.details)),
      (cameras) => emit(CamerasDiscovered(cameras)),
    );
  }

  Future<void> _onConnectToCamera(
    ConnectToCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    // Skip if no ip address (used for status updates)
    if (event.ipAddress.isEmpty) return;

    emit(CameraLoading());

    final result = await connectToCamera(
      ConnectParams(ipAddress: event.ipAddress, port: event.port),
    );

    result.fold(
      (failure) =>
          emit(CameraError(message: failure.message, details: failure.details)),
      (_) => emit(const CameraSuccess('Connected successfully')),
    );
  }

  Future<void> _onDisconnect(
    DisconnectCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());

    final result = await disconnectCamera(NoParams());

    result.fold(
      (failure) =>
          emit(CameraError(message: failure.message, details: failure.details)),
      (_) => emit(const CameraSuccess('Disconnected successfully')),
    );
  }

  Future<void> _onGetImages(
    GetCameraImagesEvent event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());

    final result = await getCameraImages(NoParams());

    result.fold(
      (failure) =>
          emit(CameraError(message: failure.message, details: failure.details)),
      (images) => emit(ImagesLoaded(images)),
    );
  }

  Future<void> _onDownloadImage(
    DownloadImageEvent event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraLoading());

    final result = await downloadImage(
      DownloadImageParams(objectHandle: event.objectHandle),
    );

    result.fold(
      (failure) =>
          emit(CameraError(message: failure.message, details: failure.details)),
      (image) => emit(ImageDownloaded(image)),
    );
  }

  Future<void> _onRefreshImages(
    RefreshImagesEvent event,
    Emitter<CameraState> emit,
  ) async {
    add(GetCameraImagesEvent());
  }

  @override
  Future<void> close() {
    _connectionStatusSubscription?.cancel();
    _logStreamSubscription?.cancel();
    _imagesStreamSubscription?.cancel();
    return super.close();
  }
}
