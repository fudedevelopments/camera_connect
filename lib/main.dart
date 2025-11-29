import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CameraConnectApp());
}

class CameraConnectApp extends StatelessWidget {
  const CameraConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
