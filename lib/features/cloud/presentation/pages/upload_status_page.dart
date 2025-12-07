import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/upload_status.dart';
import '../bloc/cloud_bloc.dart';
import '../bloc/cloud_state.dart';

/// Upload Status Page showing all photo uploads for an event
class UploadStatusPage extends StatelessWidget {
  final String eventId;
  final String eventName;

  const UploadStatusPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Status'), elevation: 0),
      body: BlocBuilder<CloudBloc, CloudState>(
        builder: (context, state) {
          final uploadStatuses = state is CloudLoaded
              ? (state.uploadStatuses[eventId] ?? [])
              : <UploadStatus>[];

          if (uploadStatuses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_done, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No uploads yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photos will appear here when auto-upload is enabled',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Count by status
          final uploading = uploadStatuses
              .where(
                (s) =>
                    s.state == UploadState.detected ||
                    s.state == UploadState.gettingUrl ||
                    s.state == UploadState.uploading,
              )
              .length;
          final completed = uploadStatuses
              .where((s) => s.state == UploadState.completed)
              .length;
          final failed = uploadStatuses
              .where((s) => s.state == UploadState.failed)
              .length;

          return Column(
            children: [
              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total',
                          uploadStatuses.length.toString(),
                          Icons.photo_library,
                        ),
                        _buildSummaryItem(
                          'Uploading',
                          uploading.toString(),
                          Icons.cloud_upload,
                        ),
                        _buildSummaryItem(
                          'Completed',
                          completed.toString(),
                          Icons.check_circle,
                        ),
                        _buildSummaryItem(
                          'Failed',
                          failed.toString(),
                          Icons.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upload List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: uploadStatuses.length,
                  itemBuilder: (context, index) {
                    final status = uploadStatuses.reversed.toList()[index];
                    return _buildUploadItem(context, status);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildUploadItem(BuildContext context, UploadStatus status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.state) {
      case UploadState.detected:
        statusColor = Colors.blue;
        statusIcon = Icons.fiber_new;
        statusText = 'Detected';
        break;
      case UploadState.gettingUrl:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'Getting URL';
        break;
      case UploadState.uploading:
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_upload;
        statusText = 'Uploading';
        break;
      case UploadState.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case UploadState.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: File(status.filePath).existsSync()
                    ? Image.file(
                        File(status.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image,
                            size: 30,
                            color: Colors.grey[400],
                          );
                        },
                      )
                    : Icon(Icons.image, size: 30, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' • ${_getTimeAgo(status.detectedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (status.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      status.errorMessage!,
                      style: TextStyle(fontSize: 11, color: Colors.red[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (status.state == UploadState.uploading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: status.progress > 0 ? status.progress : null,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ],
                ],
              ),
            ),

            // Status indicator
            if (status.state == UploadState.uploading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              Icon(statusIcon, color: statusColor, size: 24),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
