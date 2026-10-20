import 'dart:async';
import '../domain/auth_user.dart';

abstract class IAuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<void> requestOtp(String phoneNumber);
  Future<AuthUser> verifyOtp({required String phoneNumber, required String otpCode});
  Future<void> signOut();
}

/// Mock Auth Repository for offline development and local test-drives.
/// Allows OTP "123456" for any valid 10-digit Indian mobile number.
class MockAuthRepository implements IAuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  // Pre-seeded test seller user (matches seed.sql)
  static const String testSellerId = '00000000-0000-0000-0000-000000000001';
  static const String testPhoneNumber = '+919876543210';

  MockAuthRepository() {
    // Start unauthenticated by default
    _currentUser = null;
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<void> requestOtp(String phoneNumber) async {
    // Simulate brief network roundtrip
    await Future.delayed(const Duration(milliseconds: 600));

    // Basic validation for 10-digit phone
    final sanitized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (sanitized.length < 10) {
      throw Exception('Please enter a valid 10-digit mobile number.');
    }
  }

  @override
  Future<AuthUser> verifyOtp({required String phoneNumber, required String otpCode}) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // In dev mock mode, "123456" is always accepted
    if (otpCode != '123456') {
      throw Exception('Invalid verification code. For development, use: 123456');
    }

    final sanitized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final isTestSeller = sanitized.endsWith('9876543210');

    _currentUser = AuthUser(
      id: isTestSeller ? testSellerId : 'user_${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phoneNumber,
      email: isTestSeller ? 'seller@chikankarijaipur.in' : null,
      isMock: true,
      createdAt: DateTime.now(),
    );

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
}
