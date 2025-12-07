import '../../domain/entities/upload_url.dart';

/// Upload URL model - Data layer
class UploadUrlModel extends UploadUrl {
  const UploadUrlModel({required super.uploadUrl, required super.photoKey});

  factory UploadUrlModel.fromJson(Map<String, dynamic> json) {
    return UploadUrlModel(
      uploadUrl: json['upload_url'] as String,
      photoKey:
          json['photo_name'] as String, // API returns photo_name, not photo_key
    );
  }

  Map<String, dynamic> toJson() {
    return {'upload_url': uploadUrl, 'photo_key': photoKey};
  }
}
