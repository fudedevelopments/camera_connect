import '../../domain/entities/user_profile.dart';

/// User profile model - Data layer (DTO)
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.isEmailVerified,
    required super.isPhoneVerified,
    super.lastLoginAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      isEmailVerified: (json['is_email_verified'] as int) == 1,
      isPhoneVerified: (json['is_phone_verified'] as int) == 1,
      lastLoginAt: json['last_login_at'] as int?,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'is_email_verified': isEmailVerified ? 1 : 0,
      'is_phone_verified': isPhoneVerified ? 1 : 0,
      'last_login_at': lastLoginAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
