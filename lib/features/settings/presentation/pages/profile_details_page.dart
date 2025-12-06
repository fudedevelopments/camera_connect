import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user_profile.dart';

/// Profile details page showing complete user information
class ProfileDetailsPage extends StatelessWidget {
  final UserProfile profile;

  const ProfileDetailsPage({super.key, required this.profile});

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${profile.id}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contact Information
            const Text(
              'CONTACT INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: profile.email,
                    trailing: profile.isEmailVerified
                        ? const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 20,
                          )
                        : const Icon(Icons.cancel, color: Colors.red, size: 20),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: profile.phone,
                    trailing: profile.isPhoneVerified
                        ? const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 20,
                          )
                        : const Icon(Icons.cancel, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Verification Status
            const Text(
              'VERIFICATION STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email Verification',
                    value: profile.isEmailVerified
                        ? 'Verified'
                        : 'Not Verified',
                    valueColor: profile.isEmailVerified
                        ? Colors.green
                        : Colors.red,
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone Verification',
                    value: profile.isPhoneVerified
                        ? 'Verified'
                        : 'Not Verified',
                    valueColor: profile.isPhoneVerified
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Information
            const Text(
              'ACCOUNT INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Account Created',
                    value: _formatTimestamp(profile.createdAt),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.update_outlined,
                    title: 'Last Updated',
                    value: _formatTimestamp(profile.updatedAt),
                  ),
                  const Divider(height: 1),
                  _buildInfoTile(
                    icon: Icons.login_outlined,
                    title: 'Last Login',
                    value: _formatTimestamp(profile.lastLoginAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
    Color? valueColor,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontWeight: valueColor != null ? FontWeight.w600 : null,
        ),
      ),
      trailing: trailing,
    );
  }
}
