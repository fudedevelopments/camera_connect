import 'package:flutter/material.dart';

import '../models/connection_status.dart';
import '../models/discovered_camera.dart';
import '../services/camera_service.dart';

/// Connection mode enum
enum ConnectionMode { auto, manual }

/// Connection panel widget for managing camera connection
class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({super.key});

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  final CameraService _cameraService = CameraService();
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '15740',
  );

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionMode _connectionMode = ConnectionMode.auto;
  String? _cameraName;
  Map<String, dynamic>? _cameraInfo;
  bool _isLoading = false;
  List<DiscoveredCamera> _discoveredCameras = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _status = _cameraService.currentStatus;
    _cameraName = _cameraService.connectedCameraName;

    _cameraService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
          _cameraName = _cameraService.connectedCameraName;
        });
      }
    });
  }

  Future<void> _autoConnect() async {
    setState(() => _isLoading = true);

    await _cameraService.autoConnect();

    if (_cameraService.currentStatus == ConnectionStatus.connected) {
      _cameraInfo = await _cameraService.getCameraInfo();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _discoverCameras() async {
    setState(() {
      _isDiscovering = true;
      _discoveredCameras = [];
    });

    final cameras = await _cameraService.discoverCameras();

    setState(() {
      _discoveredCameras = cameras;
      _isDiscovering = false;
    });
  }

  Future<void> _connectToCamera(DiscoveredCamera camera) async {
    setState(() => _isLoading = true);

    await _cameraService.connect(camera.ipAddress, port: camera.port);

    if (_cameraService.currentStatus == ConnectionStatus.connected) {
      _cameraInfo = await _cameraService.getCameraInfo();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _manualConnect() async {
    setState(() => _isLoading = true);

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 15740;

    await _cameraService.connect(ip, port: port);

    if (_cameraService.currentStatus == ConnectionStatus.connected) {
      _cameraInfo = await _cameraService.getCameraInfo();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _cameraService.disconnect();
    setState(() {
      _isLoading = false;
      _cameraInfo = null;
      _discoveredCameras = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Card
          _buildStatusCard(),
          const SizedBox(height: 16),

          // Mode Selector (only when disconnected)
          if (!_status.isConnected && !_status.isConnecting)
            _buildModeSelector(),

          // Auto Mode Content
          if (!_status.isConnected &&
              !_status.isConnecting &&
              _connectionMode == ConnectionMode.auto)
            _buildAutoModeContent(),

          // Manual Mode Content
          if (!_status.isConnected &&
              !_status.isConnecting &&
              _connectionMode == ConnectionMode.manual)
            _buildManualModeContent(),

          // Camera Info (when connected)
          if (_status.isConnected) _buildCameraInfoCard(),

          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatusIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _status.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_cameraName != null)
                    Text(
                      _cameraName!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  if (_cameraService.connectedIpAddress != null)
                    Text(
                      _cameraService.connectedIpAddress!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (_isLoading || _status.isConnecting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;

    switch (_status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ConnectionStatus.connecting:
        color = Colors.orange;
        icon = Icons.sync;
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case ConnectionStatus.disconnected:
        color = Colors.grey;
        icon = Icons.link_off;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<ConnectionMode>(
          segments: const [
            ButtonSegment(
              value: ConnectionMode.auto,
              label: Text('Auto'),
              icon: Icon(Icons.auto_fix_high),
            ),
            ButtonSegment(
              value: ConnectionMode.manual,
              label: Text('Manual'),
              icon: Icon(Icons.edit),
            ),
          ],
          selected: {_connectionMode},
          onSelectionChanged: (Set<ConnectionMode> selected) {
            setState(() {
              _connectionMode = selected.first;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAutoModeContent() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wifi_find, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Auto Discovery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Automatically find and connect to cameras on your network. '
                  'Make sure you\'re connected to your camera\'s WiFi network.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // Discover button
                OutlinedButton.icon(
                  onPressed: _isDiscovering ? null : _discoverCameras,
                  icon: _isDiscovering
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _isDiscovering ? 'Searching...' : 'Search for Cameras',
                  ),
                ),

                // Discovered cameras list
                if (_discoveredCameras.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Found ${_discoveredCameras.length} camera(s):',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._discoveredCameras.map(
                    (camera) => _buildCameraListItem(camera),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraListItem(DiscoveredCamera camera) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.camera_alt, color: Colors.blue),
        ),
        title: Text(camera.displayName),
        subtitle: Text('${camera.ipAddress}:${camera.port}'),
        trailing: ElevatedButton(
          onPressed: _isLoading ? null : () => _connectToCamera(camera),
          child: const Text('Connect'),
        ),
      ),
    );
  }

  Widget _buildManualModeContent() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Manual Connection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'Camera IP Address',
                    hintText: '192.168.0.1',
                    prefixIcon: Icon(Icons.router),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '15740',
                    prefixIcon: Icon(Icons.settings_ethernet),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Text(
                  'Common camera IPs: 192.168.0.1 (Sony/Fuji), 192.168.1.1 (Canon/Nikon)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Camera Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cameraInfo != null) ...[
              _buildInfoRow(
                'Manufacturer',
                _cameraInfo!['manufacturer'] ?? 'Unknown',
              ),
              _buildInfoRow('Model', _cameraInfo!['model'] ?? 'Unknown'),
              _buildInfoRow(
                'Serial Number',
                _cameraInfo!['serialNumber'] ?? 'Unknown',
              ),
              _buildInfoRow(
                'Firmware',
                _cameraInfo!['firmwareVersion'] ?? 'Unknown',
              ),
            ] else
              const Text('Loading camera information...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_status.isConnected) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text('Disconnect'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    _cameraInfo = await _cameraService.getCameraInfo();
                    setState(() {});
                  },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ],
      );
    }

    if (_connectionMode == ConnectionMode.auto) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _autoConnect,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_fix_high),
        label: Text(_isLoading ? 'Connecting...' : 'Auto Connect'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _manualConnect,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.link),
        label: Text(_isLoading ? 'Connecting...' : 'Connect'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
