import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class FolderPickerDialog extends StatefulWidget {
  final String? initialPath;

  const FolderPickerDialog({super.key, this.initialPath});

  @override
  State<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  late String _currentPath;
  List<Directory> _directories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath ?? '/storage/emulated/0';
    _loadDirectories();
  }

  bool _isRestrictedPath(String path) {
    // Prevent navigation to system directories
    final restrictedPaths = [
      '/data',
      '/system',
      '/proc',
      '/dev',
      '/sys',
      '/root',
    ];

    for (final restricted in restrictedPaths) {
      if (path.startsWith(restricted)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadDirectories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if path is restricted
      if (_isRestrictedPath(_currentPath)) {
        setState(() {
          _error =
              'Cannot access system directories. Please use /storage/emulated/0';
          _isLoading = false;
          _currentPath = '/storage/emulated/0';
        });
        return;
      }

      // Request permission
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Storage permission denied';
          _isLoading = false;
        });
        return;
      }

      final dir = Directory(_currentPath);
      if (!await dir.exists()) {
        setState(() {
          _error = 'Directory does not exist';
          _isLoading = false;
        });
        return;
      }

      final entities = await dir.list().toList();
      final dirs = entities
          .whereType<Directory>()
          .where((d) => !d.path.split('/').last.startsWith('.'))
          .toList();

      dirs.sort((a, b) => a.path.compareTo(b.path));

      setState(() {
        _directories = dirs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading folders: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToDirectory(String path) {
    // Prevent navigation to restricted paths
    if (_isRestrictedPath(path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot access system directories'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _currentPath = path;
    });
    _loadDirectories();
  }

  void _navigateUp() {
    final parts = _currentPath.split('/');
    if (parts.length > 2) {
      parts.removeLast();
      final newPath = parts.join('/');

      // Prevent going into restricted areas
      if (_isRestrictedPath(newPath)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot navigate to system directories'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      _navigateToDirectory(newPath);
    }
  }

  Future<void> _createNewFolder() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        final newDir = Directory('$_currentPath/${result.trim()}');
        await newDir.create();
        _loadDirectories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create folder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Select Folder',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.create_new_folder),
                  onPressed: _createNewFolder,
                  tooltip: 'Create New Folder',
                ),
              ],
            ),
            const Divider(),

            // Current Path
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_currentPath != '/storage/emulated/0')
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: _navigateUp,
                      tooltip: 'Up',
                    ),
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: const TextStyle(fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Directory List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(_error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDirectories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _directories.isEmpty
                  ? const Center(child: Text('No folders in this directory'))
                  : ListView.builder(
                      itemCount: _directories.length,
                      itemBuilder: (context, index) {
                        final dir = _directories[index];
                        final name = dir.path.split('/').last;
                        return ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.amber,
                          ),
                          title: Text(name),
                          onTap: () => _navigateToDirectory(dir.path),
                        );
                      },
                    ),
            ),

            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _currentPath),
                  child: const Text('Select This Folder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
