import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/folder_service.dart';
import '../../domain/entities/event.dart';
import '../bloc/cloud_bloc.dart';
import '../bloc/cloud_event.dart';
import '../bloc/cloud_state.dart';

/// Event details page showing event information and sync controls
class EventDetailsPage extends StatelessWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  Future<String> _getFolderPath() async {
    final folderService = sl<FolderService>();
    return await folderService.getEventFolderPath(event.eventName);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CloudBloc, CloudState>(
      listener: (context, state) {
        if (state is CloudError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is CloudLoaded) {
          // Check if sync status changed for this event
          final updatedEvent = state.events.firstWhere(
            (e) => e.id == event.id,
            orElse: () => event,
          );

          if (updatedEvent.isSynced != event.isSynced) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  updatedEvent.isSynced
                      ? 'Folder created successfully!'
                      : 'Folder removed successfully!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Event Details'), elevation: 0),
        body: BlocBuilder<CloudBloc, CloudState>(
          builder: (context, state) {
            // Get the latest event data from state
            final currentEvent = state is CloudLoaded
                ? state.events.firstWhere(
                    (e) => e.id == event.id,
                    orElse: () => event,
                  )
                : event;

            final eventDate = DateTime.fromMillisecondsSinceEpoch(
              currentEvent.eventDate,
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event, color: Colors.white, size: 48),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                currentEvent.eventName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              currentEvent.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentEvent.isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sync Status Card
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    currentEvent.isSynced
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    color: currentEvent.isSynced
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Local Sync',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentEvent.isSynced
                                            ? 'Syncing enabled'
                                            : 'Sync disabled',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: currentEvent.isSynced,
                                onChanged: (value) {
                                  context.read<CloudBloc>().add(
                                    ToggleEventSync(
                                      eventId: currentEvent.id,
                                      eventName: currentEvent.eventName,
                                      isSynced: value,
                                    ),
                                  );
                                  // Show feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? 'Creating folder for ${currentEvent.eventName}...'
                                            : 'Removing folder for ${currentEvent.eventName}...',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (currentEvent.isSynced) ...[
                            const SizedBox(height: 16),
                            FutureBuilder<String>(
                              future: _getFolderPath(),
                              builder: (context, snapshot) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.folder,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Photos will be saved to local folder',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (snapshot.hasData) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          snapshot.data!,
                                          style: TextStyle(
                                            color: Colors.green[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Event Details Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailRow(
                          Icons.calendar_today,
                          'Date',
                          '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                        ),
                        const Divider(height: 24),

                        _buildDetailRow(
                          Icons.location_on,
                          'Location',
                          currentEvent.eventLocation,
                        ),
                        const Divider(height: 24),

                        if (currentEvent.description.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.description,
                            'Description',
                            currentEvent.description,
                          ),
                          const Divider(height: 24),
                        ],

                        _buildDetailRow(
                          Icons.qr_code,
                          'QR Code',
                          currentEvent.qrCode,
                        ),
                        const Divider(height: 24),

                        _buildDetailRow(
                          Icons.link,
                          'Event URL',
                          currentEvent.fullEventUrl,
                        ),
                        const Divider(height: 24),

                        _buildDetailRow(
                          Icons.public,
                          'Published',
                          currentEvent.isPublished ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
