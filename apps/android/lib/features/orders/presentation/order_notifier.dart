import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order.dart';
import '../../../core/models/payment_evidence.dart';
import '../../../core/utils/paise_currency.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/order_repository.dart';

class OrderState {
  final List<Order> allOrders;
  final bool isLoading;
  final String? errorMessage;
  final String activeFilter; // 'all', 'needs_review', 'to_pack', 'shipped', 'delivered', 'rto'
  final String searchQuery;

  const OrderState({
    this.allOrders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.activeFilter = 'all',
    this.searchQuery = '',
  });

  List<Order> get filteredOrders {
    return allOrders.where((o) {
      // 1. Search Query Filter (Order number, customer name, phone, city)
      final q = searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          o.orderNumber.toLowerCase().contains(q) ||
          (o.customer?.name.toLowerCase().contains(q) ?? false) ||
          (o.customer?.phone.toLowerCase().contains(q) ?? false) ||
          (o.customer?.city?.toLowerCase().contains(q) ?? false);

      if (!matchesQuery) return false;

      // 2. Status Category Filter
      switch (activeFilter) {
        case 'needs_review':
          return o.hasEvidenceAwaitingReview || o.paymentStatus == PaymentStatus.pending;
        case 'to_pack':
          return o.fulfilmentStatus == FulfilmentStatus.packed ||
              o.fulfilmentStatus == FulfilmentStatus.codConfirmed ||
              o.fulfilmentStatus == FulfilmentStatus.paid;
        case 'shipped':
          return o.fulfilmentStatus == FulfilmentStatus.shipped;
        case 'delivered':
          return o.fulfilmentStatus == FulfilmentStatus.delivered;
        case 'rto':
          return o.fulfilmentStatus == FulfilmentStatus.rto ||
              o.fulfilmentStatus == FulfilmentStatus.returned;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  int get needsReviewCount =>
      allOrders.where((o) => o.hasEvidenceAwaitingReview || o.paymentStatus == PaymentStatus.pending).length;

  int get toPackCount =>
      allOrders.where((o) => o.fulfilmentStatus == FulfilmentStatus.packed || o.fulfilmentStatus == FulfilmentStatus.codConfirmed).length;

  int get shippedCount =>
      allOrders.where((o) => o.fulfilmentStatus == FulfilmentStatus.shipped).length;

  int get rtoCount =>
      allOrders.where((o) => o.fulfilmentStatus == FulfilmentStatus.rto).length;

  // Aggregate Metrics
  Paise get totalEstimatedProfit {
    final sum = allOrders.fold<int>(0, (acc, o) => acc + o.estimatedProfit.value);
    return Paise(sum);
  }

  Paise get totalRealisedProfit {
    final sum = allOrders
        .where((o) => o.realisedProfit != null)
        .fold<int>(0, (acc, o) => acc + o.realisedProfit!.value);
    return Paise(sum);
  }

  Paise get pendingCollections {
    final sum = allOrders
        .where((o) => o.paymentStatus == PaymentStatus.pending)
        .fold<int>(0, (acc, o) => acc + o.netSales.value);
    return Paise(sum);
  }

  OrderState copyWith({
    List<Order>? allOrders,
    bool? isLoading,
    String? errorMessage,
    String? activeFilter,
    String? searchQuery,
  }) {
    return OrderState(
      allOrders: allOrders ?? this.allOrders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final business = ref.watch(currentBusinessProvider);
  final businessId = business?.id ?? '11111111-1111-1111-1111-111111111111';

  final notifier = OrderNotifier(repo, businessId);
  notifier.loadOrders();
  return notifier;
});

class OrderNotifier extends StateNotifier<OrderState> {
  final IOrderRepository _repo;
  final String _businessId;

  OrderNotifier(this._repo, this._businessId) : super(const OrderState());

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _repo.getOrders(_businessId);
      state = state.copyWith(allOrders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> updateOrderStatus(
    String orderId,
    FulfilmentStatus newStatus, {
    PaymentStatus? newPaymentStatus,
    String? trackingNumber,
    String? courierName,
  }) async {
    await _repo.updateOrderStatus(
      orderId,
      newStatus,
      newPaymentStatus: newPaymentStatus,
      trackingNumber: trackingNumber,
      courierName: courierName,
    );
    await loadOrders();
  }

  Future<void> updateCostAssumptions(
    String orderId, {
    required int productCostMinor,
    required int packagingCostMinor,
    required int shippingMinor,
  }) async {
    await _repo.updateOrderCostAssumptions(
      orderId,
      productCostMinor: productCostMinor,
      packagingCostMinor: packagingCostMinor,
      shippingMinor: shippingMinor,
    );
    await loadOrders();
  }

  Future<void> reviewEvidence(String orderId, String evidenceId, ReviewStatus status) async {
    await _repo.reviewPaymentEvidence(orderId, evidenceId, status);
    await loadOrders();
  }
}
