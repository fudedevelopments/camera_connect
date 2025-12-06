import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends SettingsEvent {
  const LoadProfileEvent();
}

class LogoutEvent extends SettingsEvent {
  const LogoutEvent();
}
