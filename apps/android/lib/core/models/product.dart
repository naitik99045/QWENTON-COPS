import '../utils/paise_currency.dart';

class Product {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final String? sku;
  final String currency;
  final Paise sellingPrice;
  final Paise discount;
  final Paise productCost; // COGS
  final Paise packagingCost;
  final Paise shippingCost;
  final double paymentFeeRate;
  final double expectedReturnRate;
  final double expectedRtoRate;
  final int stockQuantity;
  final bool isActive;
  final List<ProductVariant> variants;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.sku,
    this.currency = 'INR',
    required this.sellingPrice,
    this.discount = const Paise(0),
    required this.productCost,
    this.packagingCost = const Paise(0),
    this.shippingCost = const Paise(0),
    this.paymentFeeRate = 0.0200,
    this.expectedReturnRate = 5.0,
    this.expectedRtoRate = 10.0,
    this.stockQuantity = 0,
    this.isActive = true,
    this.variants = const [],
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// True net sale price after discount
  Paise get netPrice => sellingPrice - discount;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sku: json['sku'] as String?,
      currency: json['currency'] as String? ?? 'INR',
      sellingPrice: Paise(json['selling_price_minor'] as int),
      discount: Paise(json['discount_minor'] as int? ?? 0),
      productCost: Paise(json['product_cost_minor'] as int),
      packagingCost: Paise(json['packaging_cost_minor'] as int? ?? 0),
      shippingCost: Paise(json['shipping_cost_minor'] as int? ?? 0),
      paymentFeeRate: (json['payment_fee_rate'] as num?)?.toDouble() ?? 0.0200,
      expectedReturnRate: (json['expected_return_rate'] as num?)?.toDouble() ?? 5.0,
      expectedRtoRate: (json['expected_rto_rate'] as num?)?.toDouble() ?? 10.0,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      imageUrls: (json['images'] as List<dynamic>?)
              ?.map((img) => img is String ? img : (img['image_url'] as String))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'description': description,
      'sku': sku,
      'currency': currency,
      'selling_price_minor': sellingPrice.value,
      'discount_minor': discount.value,
      'product_cost_minor': productCost.value,
      'packaging_cost_minor': packagingCost.value,
      'shipping_cost_minor': shippingCost.value,
      'payment_fee_rate': paymentFeeRate,
      'expected_return_rate': expectedReturnRate,
      'expected_rto_rate': expectedRtoRate,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
    };
  }
}

class ProductVariant {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final Paise priceDelta;
  final int stockQuantity;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.priceDelta = const Paise(0),
    this.stockQuantity = 0,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      priceDelta: Paise(json['price_delta_minor'] as int? ?? 0),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'sku': sku,
      'price_delta_minor': priceDelta.value,
      'stock_quantity': stockQuantity,
    };
  }
}
