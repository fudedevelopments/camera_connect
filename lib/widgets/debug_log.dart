import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/log_entry.dart';
import '../services/camera_service.dart';

/// Debug log widget for displaying connection and operation logs
class DebugLog extends StatefulWidget {
  const DebugLog({super.key});

  @override
  State<DebugLog> createState() => _DebugLogState();
}

class _DebugLogState extends State<DebugLog> {
  final CameraService _cameraService = CameraService();
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _logSubscription;
  bool _autoScroll = true;
  bool _showDebugLogs = true;

  @override
  void initState() {
    super.initState();
    _logSubscription = _cameraService.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          _logs.add(entry);
          // Keep only last 500 logs
          if (_logs.length > 500) {
            _logs.removeAt(0);
          }
        });

        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  List<LogEntry> get _filteredLogs {
    if (_showDebugLogs) {
      return _logs;
    }
    return _logs.where((log) => log.level.toUpperCase() != 'DEBUG').toList();
  }

  void _copyLogs() {
    final text = _filteredLogs.map((log) => log.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _exportLogs() {
    final text = _filteredLogs.map((log) => log.toString()).join('\n');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Logs'),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${_filteredLogs.length} logs',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              // Filter toggle
              IconButton(
                icon: Icon(
                  _showDebugLogs ? Icons.bug_report : Icons.bug_report_outlined,
                  size: 20,
                ),
                tooltip: _showDebugLogs ? 'Hide debug logs' : 'Show debug logs',
                onPressed: () {
                  setState(() {
                    _showDebugLogs = !_showDebugLogs;
                  });
                },
              ),
              // Auto-scroll toggle
              IconButton(
                icon: Icon(
                  _autoScroll
                      ? Icons.vertical_align_bottom
                      : Icons.vertical_align_center,
                  size: 20,
                ),
                tooltip: _autoScroll
                    ? 'Disable auto-scroll'
                    : 'Enable auto-scroll',
                onPressed: () {
                  setState(() {
                    _autoScroll = !_autoScroll;
                  });
                },
              ),
              // Copy button
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy logs',
                onPressed: _logs.isEmpty ? null : _copyLogs,
              ),
              // Export button
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                tooltip: 'Export logs',
                onPressed: _logs.isEmpty ? null : _exportLogs,
              ),
              // Clear button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Clear logs',
                onPressed: _logs.isEmpty ? null : _clearLogs,
              ),
            ],
          ),
        ),

        // Log list
        Expanded(
          child: _filteredLogs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    return _buildLogEntry(_filteredLogs[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('No Logs Yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Connection and operation logs will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: entry.details != null ? () => _showLogDetails(entry) : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: entry.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(entry.icon, size: 14, color: entry.color),
              ),
              const SizedBox(width: 8),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.formattedTimestamp,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: entry.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.level,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: entry.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(entry.message, style: const TextStyle(fontSize: 13)),
                    if (entry.details != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.details!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Details indicator
              if (entry.details != null)
                Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetails(LogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(entry.icon, color: entry.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.message,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          entry.formattedTimestamp,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: entry.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  entry.details ?? 'No details available',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
