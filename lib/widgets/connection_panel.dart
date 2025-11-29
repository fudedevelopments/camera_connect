import 'package:flutter/material.dart';

import '../models/connection_status.dart';
import '../services/camera_service.dart';

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
  String? _cameraName;
  Map<String, dynamic>? _cameraInfo;
  bool _isLoading = false;

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

  Future<void> _connect() async {
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

          // Connection Settings
          if (!_status.isConnected) _buildConnectionSettings(),

          // Camera Info
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
            if (_isLoading)
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

  Widget _buildConnectionSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Settings',
              style: Theme.of(context).textTheme.titleMedium,
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
              'Default PTP/IP port is 15740. Most cameras use this port.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : (_status.isConnected ? _disconnect : _connect),
            icon: Icon(_status.isConnected ? Icons.link_off : Icons.link),
            label: Text(_status.isConnected ? 'Disconnect' : 'Connect'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _status.isConnected ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_status.isConnected) ...[
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
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
