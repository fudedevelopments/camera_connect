import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/usecases/get_profile_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetProfileUseCase getProfileUseCase;
  final LogoutUseCase logoutUseCase;

  SettingsBloc({required this.getProfileUseCase, required this.logoutUseCase})
    : super(const SettingsInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await getProfileUseCase(NoParams());

    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) => emit(const LogoutSuccess()),
    );
  }
}
