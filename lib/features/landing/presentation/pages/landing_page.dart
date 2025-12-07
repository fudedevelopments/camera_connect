import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../camera/presentation/pages/camera_connect_page.dart';
import '../../../gallery/presentation/pages/gallery_page.dart';
import '../../../cloud/presentation/pages/cloud_page.dart';
import '../../../cloud/presentation/bloc/cloud_bloc.dart';
import '../../../cloud/presentation/bloc/cloud_event.dart';
import '../../../settings/presentation/pages/settings_page.dart';

/// Main landing screen with bottom navigation
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;
  final Set<int> _visitedPages = {0}; // Track which pages have been visited
  bool _hasLoadedCloudEvents = false;

  @override
  void initState() {
    super.initState();
    // Listen for tab changes to load cloud events when Cloud tab is first visited
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
      _visitedPages.add(index);
    });

    // Load cloud events when Cloud tab is first visited
    if (index == 2 && !_hasLoadedCloudEvents) {
      _hasLoadedCloudEvents = true;
      context.read<CloudBloc>().add(LoadEvents());
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const CameraConnectPage();
      case 1:
        return const GalleryPage();
      case 2:
        return const CloudPage();
      case 3:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, (index) {
          // Only build pages that have been visited
          if (_visitedPages.contains(index)) {
            return _buildPage(index);
          }
          return const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Cloud',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
