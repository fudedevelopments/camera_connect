import 'package:get_it/get_it.dart';

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
}
