import '../utils/paise_currency.dart';

enum UserRole { owner, staff }

class Business {
  final String id;
  final String ownerUserId;
  final String name;
  final String preferredLanguage; // 'en' or 'hi'
  final String whatsappNumber;
  final String? gstinEncrypted;
  final Paise defaultShippingCost;
  final Paise defaultPackagingCost;
  final double defaultReturnRate;
  final double defaultRtoRate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.ownerUserId,
    required this.name,
    this.preferredLanguage = 'en',
    required this.whatsappNumber,
    this.gstinEncrypted,
    this.defaultShippingCost = const Paise(6000), // ₹60.00
    this.defaultPackagingCost = const Paise(1500), // ₹15.00
    this.defaultReturnRate = 8.0,
    this.defaultRtoRate = 12.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: json['name'] as String,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      whatsappNumber: json['whatsapp_number'] as String,
      gstinEncrypted: json['gstin_encrypted'] as String?,
      defaultShippingCost: Paise(json['default_shipping_cost_minor'] as int? ?? 6000),
      defaultPackagingCost: Paise(json['default_packaging_cost_minor'] as int? ?? 1500),
      defaultReturnRate: (json['default_return_rate'] as num?)?.toDouble() ?? 8.0,
      defaultRtoRate: (json['default_rto_rate'] as num?)?.toDouble() ?? 12.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'name': name,
      'preferred_language': preferredLanguage,
      'whatsapp_number': whatsappNumber,
      'gstin_encrypted': gstinEncrypted,
      'default_shipping_cost_minor': defaultShippingCost.value,
      'default_packaging_cost_minor': defaultPackagingCost.value,
      'default_return_rate': defaultReturnRate,
      'default_rto_rate': defaultRtoRate,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class BusinessMember {
  final String id;
  final String businessId;
  final String userId;
  final UserRole role;
  final DateTime createdAt;

  const BusinessMember({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.role,
    required this.createdAt,
  });

  factory BusinessMember.fromJson(Map<String, dynamic> json) {
    return BusinessMember(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      userId: json['user_id'] as String,
      role: (json['role'] as String) == 'owner' ? UserRole.owner : UserRole.staff,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
