import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/product_repository.dart';

class ProductState {
  final List<Product> allProducts;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool filterActiveOnly;

  const ProductState({
    this.allProducts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.filterActiveOnly = false,
  });

  List<Product> get filteredProducts {
    return allProducts.where((p) {
      final matchesSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (p.sku != null && p.sku!.toLowerCase().contains(searchQuery.toLowerCase()));
      final matchesActive = !filterActiveOnly || p.isActive;
      return matchesSearch && matchesActive;
    }).toList();
  }

  ProductState copyWith({
    List<Product>? allProducts,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? filterActiveOnly,
  }) {
    return ProductState(
      allProducts: allProducts ?? this.allProducts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterActiveOnly: filterActiveOnly ?? this.filterActiveOnly,
    );
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final business = ref.watch(currentBusinessProvider);
  final businessId = business?.id ?? '11111111-1111-1111-1111-111111111111';

  final notifier = ProductNotifier(repo, businessId);
  notifier.loadProducts();
  return notifier;
});

class ProductNotifier extends StateNotifier<ProductState> {
  final IProductRepository _repo;
  final String _businessId;

  ProductNotifier(this._repo, this._businessId) : super(const ProductState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final products = await _repo.getProducts(_businessId);
      state = state.copyWith(allProducts: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleFilterActiveOnly() {
    state = state.copyWith(filterActiveOnly: !state.filterActiveOnly);
  }

  Future<void> toggleProductActive(String productId, bool isActive) async {
    await _repo.toggleProductActive(productId, isActive);
    await loadProducts();
  }

  Future<Product> addProduct({
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
    final product = await _repo.addProduct(
      businessId: _businessId,
      name: name,
      description: description,
      sku: sku,
      sellingPriceMinor: sellingPriceMinor,
      discountMinor: discountMinor,
      productCostMinor: productCostMinor,
      packagingCostMinor: packagingCostMinor,
      shippingCostMinor: shippingCostMinor,
      paymentFeeRate: paymentFeeRate,
      expectedReturnRate: expectedReturnRate,
      expectedRtoRate: expectedRtoRate,
      stockQuantity: stockQuantity,
      variants: variants,
      imageUrls: imageUrls,
    );
    await loadProducts();
    return product;
  }
}
