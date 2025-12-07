import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../core/services/secure_storage_service.dart';
import '../../core/services/folder_service.dart';
import '../../core/services/folder_watcher_service.dart';
import '../../core/services/photo_upload_service.dart';
import '../../core/services/upload_tracker_service.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/camera/data/datasources/camera_local_data_source.dart';
import '../../features/camera/data/datasources/camera_remote_data_source.dart';
import '../../features/camera/data/repositories/camera_repository_impl.dart';
import '../../features/camera/domain/repositories/camera_repository.dart';
import '../../features/camera/domain/usecases/connect_to_camera.dart';
import '../../features/camera/domain/usecases/disconnect_camera.dart';
import '../../features/camera/domain/usecases/discover_cameras.dart';
import '../../features/camera/domain/usecases/get_camera_images.dart';
import '../../features/camera/domain/usecases/get_connection_status.dart';
import '../../features/camera/domain/usecases/download_image.dart';
import '../../features/camera/presentation/bloc/camera_bloc.dart';
import '../../features/cloud/data/datasources/event_remote_data_source.dart';
import '../../features/cloud/data/repositories/event_repository_impl.dart';
import '../../features/cloud/domain/repositories/event_repository.dart';
import '../../features/cloud/domain/usecases/get_events.dart';
import '../../features/cloud/domain/usecases/get_upload_url.dart';
import '../../features/cloud/domain/usecases/toggle_event_active.dart';
import '../../features/cloud/presentation/bloc/cloud_bloc.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Camera
  // Bloc
  sl.registerFactory(
    () => CameraBloc(
      connectToCamera: sl(),
      disconnectCamera: sl(),
      discoverCameras: sl(),
      getCameraImages: sl(),
      getConnectionStatus: sl(),
      downloadImage: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => ConnectToCamera(sl()));
  sl.registerLazySingleton(() => DisconnectCamera(sl()));
  sl.registerLazySingleton(() => DiscoverCameras(sl()));
  sl.registerLazySingleton(() => GetCameraImages(sl()));
  sl.registerLazySingleton(() => GetConnectionStatus(sl()));
  sl.registerLazySingleton(() => DownloadImage(sl()));

  // Repository
  sl.registerLazySingleton<CameraRepository>(
    () => CameraRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CameraRemoteDataSource>(
    () => CameraRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<CameraLocalDataSource>(
    () => CameraLocalDataSourceImpl(),
  );

  //! Core
  // Add other core dependencies here if needed
  sl.registerLazySingleton(() => SecureStorageService(secureStorage: sl()));
  sl.registerLazySingleton(() => FolderService(storageService: sl()));
  sl.registerLazySingleton(() => FolderWatcherService());
  sl.registerLazySingleton(() => PhotoUploadService(dio: sl()));
  sl.registerLazySingleton(() => UploadTrackerService());

  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  //! Features - Settings
  // Bloc
  sl.registerFactory(
    () => SettingsBloc(
      getProfileUseCase: sl(),
      logoutUseCase: sl(),
      folderService: sl(),
    ),
  );

  //! Features - Cloud
  // Bloc
  sl.registerFactory(
    () => CloudBloc(
      getEventsUseCase: sl(),
      toggleEventActiveUseCase: sl(),
      getUploadUrlUseCase: sl(),
      folderService: sl(),
      folderWatcherService: sl(),
      photoUploadService: sl(),
      uploadTrackerService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetEventsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleEventActiveUseCase(sl()));
  sl.registerLazySingleton(() => GetUploadUrl(sl()));

  // Repository
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(dio: sl(), secureStorage: sl()),
  );

  //! External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}
