import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/paise_currency.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts(String businessId);
  Future<Product?> getProductById(String id);
  Future<Product> addProduct({
    required String businessId,
    required String name,
    String? description,
    String? sku,
    required int sellingPriceMinor,
    int discountMinor = 0,
    required int productCostMinor,
    int packagingCostMinor = 0,
    int shippingCostMinor = 0,
    double paymentFeeRate = 0.0200,
    double expectedReturnRate = 5.0,
    double expectedRtoRate = 10.0,
    int stockQuantity = 0,
    List<ProductVariant> variants = const [],
    List<String> imageUrls = const [],
  });
  Future<Product> updateProduct(Product product);
  Future<void> toggleProductActive(String productId, bool isActive);
  Future<String> generateStorefrontLink(String productId);
}

class MockProductRepository implements IProductRepository {
  final List<Product> _products = [];

  MockProductRepository() {
    _seedProducts();
  }

  void _seedProducts() {
    _products.addAll([
      Product(
        id: '22222222-2222-2222-2222-222222222221',
        businessId: '11111111-1111-1111-1111-111111111111',
        name: 'Hand Embroidered Chikankari Kurti - Pastel Pink',
        description: 'Pure modal cotton fabric with intricate hand embroidery from Lucknow artisans. Breathable, comfortable, and elegant.',
        sku: 'CHK-PK-01',
        currency: 'INR',
        sellingPrice: const Paise(99900), // ₹999
        discount: const Paise(5000),      // ₹50
        productCost: const Paise(32000),   // ₹320
        packagingCost: const Paise(2500),  // ₹25
        shippingCost: const Paise(7000),   // ₹70
        paymentFeeRate: 0.0200,
        expectedReturnRate: 5.0,
        expectedRtoRate: 10.0,
        stockQuantity: 45,
        isActive: true,
        variants: const [
          ProductVariant(id: '33333333-3333-3333-3333-333333333311', productId: '22222222-2222-2222-2222-222222222221', name: 'Size: S', sku: 'CHK-PK-S', stockQuantity: 10),
          ProductVariant(id: '33333333-3333-3333-3333-333333333312', productId: '22222222-2222-2222-2222-222222222221', name: 'Size: M', sku: 'CHK-PK-M', stockQuantity: 15),
          ProductVariant(id: '33333333-3333-3333-3333-333333333313', productId: '22222222-2222-2222-2222-222222222221', name: 'Size: L', sku: 'CHK-PK-L', stockQuantity: 12),
          ProductVariant(id: '33333333-3333-3333-3333-333333333314', productId: '22222222-2222-2222-2222-222222222221', name: 'Size: XL', sku: 'CHK-PK-XL', priceDelta: Paise(5000), stockQuantity: 8),
        ],
        imageUrls: const [
          'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&auto=format&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Product(
        id: '22222222-2222-2222-2222-222222222222',
        businessId: '11111111-1111-1111-1111-111111111111',
        name: 'Pure Cotton Floral Anarkali Kurta Set with Dupatta',
        description: 'Premium mulmul cotton set with hand block print and matching chiffon dupatta.',
        sku: 'ANR-FL-02',
        currency: 'INR',
        sellingPrice: const Paise(149900), // ₹1499
        discount: const Paise(0),
        productCost: const Paise(52000),   // ₹520
        packagingCost: const Paise(3000),  // ₹30
        shippingCost: const Paise(8000),   // ₹80
        paymentFeeRate: 0.0200,
        expectedReturnRate: 6.0,
        expectedRtoRate: 12.0,
        stockQuantity: 28,
        isActive: true,
        variants: const [
          ProductVariant(id: '33333333-3333-3333-3333-333333333321', productId: '22222222-2222-2222-2222-222222222222', name: 'Size: M', sku: 'ANR-FL-M', stockQuantity: 14),
          ProductVariant(id: '33333333-3333-3333-3333-333333333322', productId: '22222222-2222-2222-2222-222222222222', name: 'Size: L', sku: 'ANR-FL-L', stockQuantity: 14),
        ],
        imageUrls: const [
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&auto=format&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Product(
        id: '22222222-2222-2222-2222-222222222223',
        businessId: '11111111-1111-1111-1111-111111111111',
        name: 'Traditional Oxidised Silver Peacock Jhumka',
        description: 'Handcrafted brass oxidised earrings with delicate ghungroos. Lightweight and skin-friendly.',
        sku: 'JHM-SL-03',
        currency: 'INR',
        sellingPrice: const Paise(34900), // ₹349
        discount: const Paise(0),
        productCost: const Paise(8000),   // ₹80
        packagingCost: const Paise(1500), // ₹15
        shippingCost: const Paise(5000),  // ₹50
        paymentFeeRate: 0.0200,
        expectedReturnRate: 2.0,
        expectedRtoRate: 5.0,
        stockQuantity: 80,
        isActive: true,
        imageUrls: const [
          'https://images.unsplash.com/photo-1630019852942-f89202989a59?w=600&auto=format&fit=crop',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Future<List<Product>> getProducts(String businessId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _products.where((p) => p.businessId == businessId).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> addProduct({
    required String businessId,
    required String name,
    String? description,
    String? sku,
    required int sellingPriceMinor,
    int discountMinor = 0,
    required int productCostMinor,
    int packagingCostMinor = 0,
    int shippingCostMinor = 0,
    double paymentFeeRate = 0.0200,
    double expectedReturnRate = 5.0,
    double expectedRtoRate = 10.0,
    int stockQuantity = 0,
    List<ProductVariant> variants = const [],
    List<String> imageUrls = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newProduct = Product(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      name: name,
      description: description,
      sku: sku,
      currency: 'INR',
      sellingPrice: Paise(sellingPriceMinor),
      discount: Paise(discountMinor),
      productCost: Paise(productCostMinor),
      packagingCost: Paise(packagingCostMinor),
      shippingCost: Paise(shippingCostMinor),
      paymentFeeRate: paymentFeeRate,
      expectedReturnRate: expectedReturnRate,
      expectedRtoRate: expectedRtoRate,
      stockQuantity: stockQuantity,
      isActive: true,
      variants: variants,
      imageUrls: imageUrls.isNotEmpty
          ? imageUrls
          : ['https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=600&auto=format&fit=crop'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _products.insert(0, newProduct);
    return newProduct;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
    }
    return product;
  }

  @override
  Future<void> toggleProductActive(String productId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final old = _products[index];
      _products[index] = Product(
        id: old.id,
        businessId: old.businessId,
        name: old.name,
        description: old.description,
        sku: old.sku,
        currency: old.currency,
        sellingPrice: old.sellingPrice,
        discount: old.discount,
        productCost: old.productCost,
        packagingCost: old.packagingCost,
        shippingCost: old.shippingCost,
        paymentFeeRate: old.paymentFeeRate,
        expectedReturnRate: old.expectedReturnRate,
        expectedRtoRate: old.expectedRtoRate,
        stockQuantity: old.stockQuantity,
        isActive: isActive,
        variants: old.variants,
        imageUrls: old.imageUrls,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<String> generateStorefrontLink(String productId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final p = _products.firstWhere((item) => item.id == productId);
    final slug = p.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    return 'https://qwenton.store/p/${slug.substring(0, slug.length > 20 ? 20 : slug.length)}';
  }
}

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  return MockProductRepository();
});
