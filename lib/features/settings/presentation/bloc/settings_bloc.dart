import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/folder_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/usecases/get_profile_usecase.dart';
import '../../../auth/domain/usecases/logout_usecase.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetProfileUseCase getProfileUseCase;
  final LogoutUseCase logoutUseCase;
  final FolderService folderService;

  SettingsBloc({
    required this.getProfileUseCase,
    required this.logoutUseCase,
    required this.folderService,
  }) : super(const SettingsInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<LogoutEvent>(_onLogout);
    on<LoadFolderPathEvent>(_onLoadFolderPath);
    on<UpdateFolderPathEvent>(_onUpdateFolderPath);
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

  Future<void> _onLoadFolderPath(
    LoadFolderPathEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final path = await folderService.getCurrentBasePath();
      emit(FolderPathLoaded(path));
    } catch (e) {
      emit(SettingsError('Failed to load folder path: $e'));
    }
  }

  Future<void> _onUpdateFolderPath(
    UpdateFolderPathEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await folderService.setCustomFolderPath(event.folderPath);
      emit(FolderPathUpdated(event.folderPath));
    } catch (e) {
      emit(SettingsError('Failed to update folder path: $e'));
    }
  }
}
