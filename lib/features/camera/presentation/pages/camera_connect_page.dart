import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/camera_bloc.dart';
import '../bloc/camera_event.dart';
import '../bloc/camera_state.dart';
import '../../domain/entities/connection_status.dart';
import 'log_viewer_page.dart';

/// Camera Connect page - Camera connection and control
class CameraConnectPage extends StatefulWidget {
  const CameraConnectPage({super.key});

  @override
  State<CameraConnectPage> createState() => _CameraConnectPageState();
}

class _CameraConnectPageState extends State<CameraConnectPage> {
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '15740',
  );

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _cameraName;
  bool _isLoading = false;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _showLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogViewerPage()),
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraBloc, CameraState>(
      listener: (context, state) {
        if (state is CameraLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is CameraConnectionState) {
          setState(() {
            _status = state.status;
            _cameraName = state.cameraName;
          });
        } else if (state is CamerasDiscovered) {
          _showDiscoveredCameras(state.cameras);
        } else if (state is CameraError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is CameraSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Camera Connect',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.terminal),
                      onPressed: _showLogs,
                      tooltip: 'View Logs',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Connect to your camera via PTP/IP',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 32),

                // Connection Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getStatusColor(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _cameraName ?? _status.displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_status.isConnected)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  context.read<CameraBloc>().add(
                                    DisconnectCameraEvent(),
                                  );
                                },
                                tooltip: 'Disconnect',
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || _status.isConnected
                                ? null
                                : () {
                                    context.read<CameraBloc>().add(
                                      DiscoverCamerasEvent(),
                                    );
                                  },
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              _isLoading
                                  ? 'Discovering...'
                                  : 'Discover Cameras',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Manual Connection Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manual Connection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ipController,
                          enabled: !_isLoading && !_status.isConnected,
                          decoration: InputDecoration(
                            labelText: 'IP Address',
                            hintText: '192.168.0.1',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.wifi),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _portController,
                          enabled: !_isLoading && !_status.isConnected,
                          decoration: InputDecoration(
                            labelText: 'Port',
                            hintText: '15740',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.settings_ethernet),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading || _status.isConnected
                                ? null
                                : () {
                                    final ip = _ipController.text.trim();
                                    final port =
                                        int.tryParse(
                                          _portController.text.trim(),
                                        ) ??
                                        15740;
                                    context.read<CameraBloc>().add(
                                      ConnectToCameraEvent(
                                        ipAddress: ip,
                                        port: port,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Camera Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _status.isConnected
                              ? 'Connected to ${_cameraName ?? "camera"}'
                              : 'No camera connected',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiscoveredCameras(List<dynamic> cameras) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discovered Cameras'),
        content: cameras.isEmpty
            ? const Text('No cameras found on the network')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cameras.length,
                  itemBuilder: (context, index) {
                    final camera = cameras[index];
                    return ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: Text(camera.displayName),
                      subtitle: Text('${camera.ipAddress}:${camera.port}'),
                      onTap: () {
                        Navigator.pop(context);
                        context.read<CameraBloc>().add(
                          ConnectToCameraEvent(
                            ipAddress: camera.ipAddress,
                            port: camera.port,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
