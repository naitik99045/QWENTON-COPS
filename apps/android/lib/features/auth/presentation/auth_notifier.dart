import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

enum AuthStatus {
  unauthenticated,
  otpSent,
  authenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? pendingPhoneNumber;
  final String? errorMessage;
  final bool hasCompletedOnboarding;
  final bool isDevMode;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.pendingPhoneNumber,
    this.errorMessage,
    this.hasCompletedOnboarding = false,
    this.isDevMode = true, // Default to true in development
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? pendingPhoneNumber,
    String? errorMessage,
    bool? hasCompletedOnboarding,
    bool? isDevMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      pendingPhoneNumber: pendingPhoneNumber ?? this.pendingPhoneNumber,
      errorMessage: errorMessage,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isDevMode: isDevMode ?? this.isDevMode,
    );
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return MockAuthRepository();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  void toggleDevMode(bool enabled) {
    state = state.copyWith(isDevMode: enabled);
  }

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';
      await _repo.requestOtp(formattedPhone);
      state = state.copyWith(
        status: AuthStatus.otpSent,
        pendingPhoneNumber: formattedPhone,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.pendingPhoneNumber == null) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.verifyOtp(
        phoneNumber: state.pendingPhoneNumber!,
        otpCode: otp,
      );

      // Check if user is test seller (already onboarded) or new user
      final isExistingSeller = user.id == MockAuthRepository.testSellerId;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasCompletedOnboarding: isExistingSeller,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void markOnboardingComplete() {
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }
}
