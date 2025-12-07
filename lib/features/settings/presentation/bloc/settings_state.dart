import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class ProfileLoaded extends SettingsState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class LogoutSuccess extends SettingsState {
  const LogoutSuccess();
}

class FolderPathLoaded extends SettingsState {
  final String folderPath;

  const FolderPathLoaded(this.folderPath);

  @override
  List<Object?> get props => [folderPath];
}

class FolderPathUpdated extends SettingsState {
  final String folderPath;

  const FolderPathUpdated(this.folderPath);

  @override
  List<Object?> get props => [folderPath];
}
