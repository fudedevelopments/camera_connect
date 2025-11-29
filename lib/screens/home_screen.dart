import 'package:flutter/material.dart';
import '../models/connection_status.dart';
import '../services/camera_service.dart';
import '../widgets/connection_panel.dart';
import '../widgets/image_gallery.dart';
import '../widgets/debug_log.dart';

/// Main home screen with tabs for connection, gallery, and logs  
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CameraService _cameraService = CameraService();
  int _currentIndex = 0;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _status = _cameraService.currentStatus;

    _cameraService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Connect'),
        centerTitle: true,
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _status.displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [ConnectionPanel(), ImageGallery(), DebugLog()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.link),
            selectedIcon: Icon(Icons.link),
            label: 'Connect',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _status.isConnected,
              child: const Icon(Icons.photo_library_outlined),
            ),
            selectedIcon: const Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          const NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal),
            label: 'Logs',
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.disconnected:
        return Colors.grey;
    }
  }
}
