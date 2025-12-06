import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/camera/presentation/bloc/camera_bloc.dart';
import 'features/camera/presentation/bloc/camera_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.init();

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
        home: const SplashPage(),
      ),
    );
  }
}
