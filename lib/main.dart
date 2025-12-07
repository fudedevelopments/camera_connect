import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/folder_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/camera/presentation/bloc/camera_bloc.dart';
import 'features/camera/presentation/bloc/camera_event.dart';
import 'features/cloud/presentation/bloc/cloud_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.init();

  // Initialize default folder (Documents/camera_connect)
  final folderService = di.sl<FolderService>();
  await folderService.initializeDefaultFolder();

  runApp(const CameraConnectApp());
}

class CameraConnectApp extends StatelessWidget {
  const CameraConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<AuthBloc>()),
        BlocProvider(
          create: (context) =>
              di.sl<CameraBloc>()..add(InitializeCameraEvent()),
        ),
        BlocProvider(create: (context) => di.sl<CloudBloc>()),
        BlocProvider(create: (context) => di.sl<SettingsBloc>()),
      ],
      child: MaterialApp(
        title: 'Camera Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routes: {'/login': (context) => const LoginPage()},
        home: const SplashPage(),
      ),
    );
  }
}
