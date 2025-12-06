import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.checkAuthStatusUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await checkAuthStatusUseCase(NoParams());
    result.fold((failure) => emit(AuthUnauthenticated()), (isAuthenticated) {
      if (isAuthenticated) {
        // Ideally we would get the token or user here too, but for now just assume authenticated
        // We might need to change CheckAuthStatusUseCase to return the token if valid
        // For now, let's just say authenticated with a placeholder or fetch it again if needed
        // But wait, CheckAuthStatusUseCase returns bool.
        // Let's just emit AuthAuthenticated with empty token or modify usecase.
        // I'll modify the usecase later if needed, for now empty string or fetch from local source in bloc (bad practice)
        // Actually, if it returns true, it means token exists.
        emit(const AuthAuthenticated(token: ''));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(username: event.username, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (token) => emit(AuthAuthenticated(token: token)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await logoutUseCase(NoParams());
    emit(AuthUnauthenticated());
  }
}
