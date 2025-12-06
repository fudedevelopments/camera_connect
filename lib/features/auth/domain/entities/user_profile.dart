/// User profile entity - Domain layer
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final int? lastLoginAt;
  final int createdAt;
  final int updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
