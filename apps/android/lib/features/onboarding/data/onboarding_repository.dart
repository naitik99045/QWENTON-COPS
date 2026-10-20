import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/business.dart';
import '../../../core/utils/paise_currency.dart';

abstract class IOnboardingRepository {
  Future<Business> createBusiness({
    required String ownerUserId,
    required String name,
    required String preferredLanguage,
    required String whatsappNumber,
    String? gstin,
    required int defaultShippingCostMinor,
    required int defaultPackagingCostMinor,
    required double defaultReturnRate,
    required double defaultRtoRate,
  });

  Future<Business?> getBusinessForUser(String userId);
}

class MockOnboardingRepository implements IOnboardingRepository {
  Business? _currentBusiness;

  MockOnboardingRepository() {
    // Seed default business matching seed.sql
    _currentBusiness = Business(
      id: '11111111-1111-1111-1111-111111111111',
      ownerUserId: '00000000-0000-0000-0000-000000000001',
      name: 'Chikankari Studio Jaipur',
      preferredLanguage: 'hi',
      whatsappNumber: '+919876543210',
      defaultShippingCost: const Paise(7000), // ₹70
      defaultPackagingCost: const Paise(2500), // ₹25
      defaultReturnRate: 5.0,
      defaultRtoRate: 10.0,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Business> createBusiness({
    required String ownerUserId,
    required String name,
    required String preferredLanguage,
    required String whatsappNumber,
    String? gstin,
    required int defaultShippingCostMinor,
    required int defaultPackagingCostMinor,
    required double defaultReturnRate,
    required double defaultRtoRate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    _currentBusiness = Business(
      id: 'biz_${DateTime.now().millisecondsSinceEpoch}',
      ownerUserId: ownerUserId,
      name: name,
      preferredLanguage: preferredLanguage,
      whatsappNumber: whatsappNumber,
      gstinEncrypted: gstin != null && gstin.isNotEmpty ? 'ENC_$gstin' : null,
      defaultShippingCost: Paise(defaultShippingCostMinor),
      defaultPackagingCost: Paise(defaultPackagingCostMinor),
      defaultReturnRate: defaultReturnRate,
      defaultRtoRate: defaultRtoRate,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return _currentBusiness!;
  }

  @override
  Future<Business?> getBusinessForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentBusiness?.ownerUserId == userId) {
      return _currentBusiness;
    }
    return null;
  }
}

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  return MockOnboardingRepository();
});

final currentBusinessProvider = StateProvider<Business?>((ref) {
  // Pre-fill with mock business initially
  final repo = ref.watch(onboardingRepositoryProvider) as MockOnboardingRepository;
  return repo._currentBusiness;
});
