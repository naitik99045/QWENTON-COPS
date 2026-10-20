import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/order.dart';
import '../../../core/models/payment_evidence.dart';
import '../../../core/profit_engine/profit_calculator.dart';
import '../../../core/utils/paise_currency.dart';

abstract class IOrderRepository {
  Stream<List<Order>> watchOrders(String businessId);
  Future<List<Order>> getOrders(String businessId);
  Future<Order?> getOrderById(String orderId);
  Future<Order> updateOrderStatus(
    String orderId,
    FulfilmentStatus newStatus, {
    PaymentStatus? newPaymentStatus,
    String? trackingNumber,
    String? courierName,
    String? notes,
  });
  Future<Order> updateOrderCostAssumptions(
    String orderId, {
    required int productCostMinor,
    required int packagingCostMinor,
    required int shippingMinor,
  });
  Future<void> reviewPaymentEvidence(String orderId, String evidenceId, ReviewStatus status);
}

class MockOrderRepository implements IOrderRepository {
  final List<Order> _orders = [];
  final _controller = StreamController<List<Order>>.broadcast();

  MockOrderRepository() {
    _seedOrders();
  }

  void _seedOrders() {
    const bizId = '11111111-1111-1111-1111-111111111111';

    _orders.addAll([
      // Order 1: UPI Payment Pending with Evidence "Needs Review"
      Order(
        id: '66666666-6666-6666-6666-666666666661',
        businessId: bizId,
        customerId: '55555555-5555-5555-5555-555555555551',
        orderNumber: 'QC-20261018-0001',
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.pending,
        fulfilmentStatus: FulfilmentStatus.paymentPending,
        subtotal: const Paise(99900),
        discount: const Paise(5000),
        shipping: const Paise(7000),
        paymentFee: const Paise(1898),
        productCost: const Paise(32000),
        packagingCost: const Paise(2500),
        expectedReturnCost: const Paise(2372),
        expectedRtoCost: const Paise(1400),
        estimatedProfit: const Paise(47730),
        customer: Customer(
          id: '55555555-5555-5555-5555-555555555551',
          businessId: bizId,
          name: 'Pooja Sharma',
          phone: '+919876543201',
          address: 'Flat 402, Royal Palms, Vaishali Nagar',
          pincode: '302021',
          city: 'Jaipur',
          state: 'Rajasthan',
          createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        ),
        items: const [
          OrderItem(
            id: 'item_1',
            orderId: '66666666-6666-6666-6666-666666666661',
            productId: '22222222-2222-2222-2222-222222222221',
            variantId: '33333333-3333-3333-3333-333333333312',
            quantity: 1,
            unitPrice: Paise(99900),
            unitCost: Paise(32000),
          ),
        ],
        evidenceList: [
          PaymentEvidence(
            id: 'ev_1',
            orderId: '66666666-6666-6666-6666-666666666661',
            type: EvidenceType.screenshot,
            reference: '412984928192',
            storagePath: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=600&auto=format&fit=crop',
            reviewStatus: ReviewStatus.needsReview,
            createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),

      // Order 2: COD Confirmed, To Pack
      Order(
        id: '66666666-6666-6666-6666-666666666662',
        businessId: bizId,
        customerId: '55555555-5555-5555-5555-555555555552',
        orderNumber: 'QC-20261018-0002',
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.codConfirmed,
        fulfilmentStatus: FulfilmentStatus.packed,
        subtotal: const Paise(149900),
        discount: const Paise(0),
        shipping: const Paise(8000),
        paymentFee: const Paise(0),
        productCost: const Paise(52000),
        packagingCost: const Paise(3000),
        expectedReturnCost: const Paise(4497),
        expectedRtoCost: const Paise(1920),
        estimatedProfit: const Paise(80483),
        customer: Customer(
          id: '55555555-5555-5555-5555-555555555552',
          businessId: bizId,
          name: 'Priya Patel',
          phone: '+919876543202',
          address: 'B-12, Shanti Kunj, Navrangpura',
          pincode: '380009',
          city: 'Ahmedabad',
          state: 'Gujarat',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        items: const [
          OrderItem(
            id: 'item_2',
            orderId: '66666666-6666-6666-6666-666666666662',
            productId: '22222222-2222-2222-2222-222222222222',
            quantity: 1,
            unitPrice: Paise(149900),
            unitCost: Paise(52000),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),

      // Order 3: Shipped in transit
      Order(
        id: '66666666-6666-6666-6666-666666666663',
        businessId: bizId,
        customerId: '55555555-5555-5555-5555-555555555553',
        orderNumber: 'QC-20261018-0003',
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        fulfilmentStatus: FulfilmentStatus.shipped,
        subtotal: const Paise(99900),
        discount: const Paise(0),
        shipping: const Paise(7000),
        paymentFee: const Paise(1998),
        productCost: const Paise(32000),
        packagingCost: const Paise(2500),
        expectedReturnCost: const Paise(2497),
        expectedRtoCost: const Paise(1400),
        estimatedProfit: const Paise(52505),
        trackingNumber: 'DEL198273645IN',
        courierName: 'Delhivery Surface',
        customer: Customer(
          id: '55555555-5555-5555-5555-555555555553',
          businessId: bizId,
          name: 'Rohan Mehta',
          phone: '+919876543203',
          address: 'Plot 55, Kalyani Nagar',
          pincode: '411006',
          city: 'Pune',
          state: 'Maharashtra',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        items: const [
          OrderItem(
            id: 'item_3',
            orderId: '66666666-6666-6666-6666-666666666663',
            productId: '22222222-2222-2222-2222-222222222221',
            quantity: 1,
            unitPrice: Paise(99900),
            unitCost: Paise(32000),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),

      // Order 4: RTO (Doorstep Rejection - True Loss Visible)
      Order(
        id: '66666666-6666-6666-6666-666666666664',
        businessId: bizId,
        customerId: '55555555-5555-5555-5555-555555555554',
        orderNumber: 'QC-20261018-0004',
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.failed,
        fulfilmentStatus: FulfilmentStatus.rto,
        subtotal: const Paise(34900),
        discount: const Paise(0),
        shipping: const Paise(5000),
        paymentFee: const Paise(0),
        productCost: const Paise(8000),
        packagingCost: const Paise(1500),
        expectedReturnCost: const Paise(349),
        expectedRtoCost: const Paise(500),
        estimatedProfit: const Paise(19551),
        realisedProfit: const Paise(-11500), // Realised Loss: packaging ₹15 + 2x shipping ₹100 = -₹115
        trackingNumber: 'BLR88371920IN',
        courierName: 'BlueDart Express',
        customer: Customer(
          id: '55555555-5555-5555-5555-555555555554',
          businessId: bizId,
          name: 'Ananya Sen',
          phone: '+919876543204',
          address: '14/A Ballygunge Place',
          pincode: '700019',
          city: 'Kolkata',
          state: 'West Bengal',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        items: const [
          OrderItem(
            id: 'item_4',
            orderId: '66666666-6666-6666-6666-666666666664',
            productId: '22222222-2222-2222-2222-222222222223',
            quantity: 1,
            unitPrice: Paise(34900),
            unitCost: Paise(8000),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),

      // Order 5: Delivered & Settled (Full Realised Profit)
      Order(
        id: '66666666-6666-6666-6666-666666666665',
        businessId: bizId,
        customerId: '55555555-5555-5555-5555-555555555555',
        orderNumber: 'QC-20261018-0005',
        paymentMethod: PaymentMethod.upi,
        paymentStatus: PaymentStatus.paid,
        fulfilmentStatus: FulfilmentStatus.delivered,
        subtotal: const Paise(99900),
        discount: const Paise(5000),
        shipping: const Paise(7000),
        paymentFee: const Paise(1898),
        productCost: const Paise(32000),
        packagingCost: const Paise(2500),
        expectedReturnCost: const Paise(0),
        expectedRtoCost: const Paise(0),
        estimatedProfit: const Paise(51502),
        realisedProfit: const Paise(51502), // Full profit realised
        trackingNumber: 'DEL994821034IN',
        courierName: 'Delhivery Surface',
        customer: Customer(
          id: '55555555-5555-5555-5555-555555555555',
          businessId: bizId,
          name: 'Vikram Singh',
          phone: '+919876543205',
          address: 'House 88, Gomti Nagar',
          pincode: '226010',
          city: 'Lucknow',
          state: 'Uttar Pradesh',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        items: const [
          OrderItem(
            id: 'item_5',
            orderId: '66666666-6666-6666-6666-666666666665',
            productId: '22222222-2222-2222-2222-222222222221',
            quantity: 1,
            unitPrice: Paise(99900),
            unitCost: Paise(32000),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Stream<List<Order>> watchOrders(String businessId) {
    return _controller.stream;
  }

  @override
  Future<List<Order>> getOrders(String businessId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _orders.where((o) => o.businessId == businessId).toList();
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return _orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Order> updateOrderStatus(
    String orderId,
    FulfilmentStatus newStatus, {
    PaymentStatus? newPaymentStatus,
    String? trackingNumber,
    String? courierName,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final o = _orders[index];

    // Compute realised profit if moving to terminal status
    Paise? newRealisedProfit = o.realisedProfit;
    if (newStatus == FulfilmentStatus.delivered) {
      final res = ProfitEngine.calculateRealisedProfit(
        fulfilmentStatus: 'delivered',
        subtotalMinor: o.subtotal.value,
        discountMinor: o.discount.value,
        actualProductCostMinor: o.productCost.value,
        actualPackagingCostMinor: o.packagingCost.value,
        actualShippingMinor: o.shipping.value,
        actualPaymentFeeMinor: o.paymentFee.value,
      );
      newRealisedProfit = res.realisedProfit;
    } else if (newStatus == FulfilmentStatus.rto) {
      final res = ProfitEngine.calculateRealisedProfit(
        fulfilmentStatus: 'rto',
        subtotalMinor: o.subtotal.value,
        discountMinor: o.discount.value,
        actualProductCostMinor: o.productCost.value,
        actualPackagingCostMinor: o.packagingCost.value,
        actualShippingMinor: o.shipping.value,
        actualPaymentFeeMinor: o.paymentFee.value,
      );
      newRealisedProfit = res.realisedProfit;
    }

    final updated = Order(
      id: o.id,
      businessId: o.businessId,
      customerId: o.customerId,
      orderNumber: o.orderNumber,
      paymentMethod: o.paymentMethod,
      paymentStatus: newPaymentStatus ?? (newStatus == FulfilmentStatus.paid ? PaymentStatus.paid : o.paymentStatus),
      fulfilmentStatus: newStatus,
      subtotal: o.subtotal,
      discount: o.discount,
      shipping: o.shipping,
      paymentFee: o.paymentFee,
      productCost: o.productCost,
      packagingCost: o.packagingCost,
      expectedReturnCost: o.expectedReturnCost,
      expectedRtoCost: o.expectedRtoCost,
      estimatedProfit: o.estimatedProfit,
      realisedProfit: newRealisedProfit,
      notes: notes ?? o.notes,
      trackingNumber: trackingNumber ?? o.trackingNumber,
      courierName: courierName ?? o.courierName,
      customer: o.customer,
      items: o.items,
      evidenceList: o.evidenceList,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
    );

    _orders[index] = updated;
    _controller.add(List.from(_orders));
    return updated;
  }

  @override
  Future<Order> updateOrderCostAssumptions(
    String orderId, {
    required int productCostMinor,
    required int packagingCostMinor,
    required int shippingMinor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) throw Exception('Order not found');

    final o = _orders[index];
    final profit = ProfitEngine.calculateEstimatedProfit(
      sellingPriceMinor: o.subtotal.value,
      discountMinor: o.discount.value,
      productCostMinor: productCostMinor,
      packagingCostMinor: packagingCostMinor,
      shippingCostMinor: shippingMinor,
      paymentFeeRate: o.paymentFee.value > 0 ? 0.0200 : 0.0,
    );

    final updated = Order(
      id: o.id,
      businessId: o.businessId,
      customerId: o.customerId,
      orderNumber: o.orderNumber,
      paymentMethod: o.paymentMethod,
      paymentStatus: o.paymentStatus,
      fulfilmentStatus: o.fulfilmentStatus,
      subtotal: o.subtotal,
      discount: o.discount,
      shipping: Paise(shippingMinor),
      paymentFee: profit.paymentFee,
      productCost: Paise(productCostMinor),
      packagingCost: Paise(packagingCostMinor),
      expectedReturnCost: profit.expectedReturnCost,
      expectedRtoCost: profit.expectedRtoCost,
      estimatedProfit: profit.estimatedProfit,
      realisedProfit: o.realisedProfit,
      notes: o.notes,
      trackingNumber: o.trackingNumber,
      courierName: o.courierName,
      customer: o.customer,
      items: o.items,
      evidenceList: o.evidenceList,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
    );

    _orders[index] = updated;
    _controller.add(List.from(_orders));
    return updated;
  }

  @override
  Future<void> reviewPaymentEvidence(String orderId, String evidenceId, ReviewStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final orderIndex = _orders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return;

    final o = _orders[orderIndex];
    final updatedEvidence = o.evidenceList.map((ev) {
      if (ev.id == evidenceId) {
        return PaymentEvidence(
          id: ev.id,
          orderId: ev.orderId,
          type: ev.type,
          reference: ev.reference,
          storagePath: ev.storagePath,
          reviewStatus: status,
          reviewedAt: DateTime.now(),
          notes: ev.notes,
          createdAt: ev.createdAt,
        );
      }
      return ev;
    }).toList();

    _orders[orderIndex] = Order(
      id: o.id,
      businessId: o.businessId,
      customerId: o.customerId,
      orderNumber: o.orderNumber,
      paymentMethod: o.paymentMethod,
      paymentStatus: status == ReviewStatus.verifiedBySeller ? PaymentStatus.paid : o.paymentStatus,
      fulfilmentStatus: status == ReviewStatus.verifiedBySeller && o.fulfilmentStatus == FulfilmentStatus.paymentPending
          ? FulfilmentStatus.paid
          : o.fulfilmentStatus,
      subtotal: o.subtotal,
      discount: o.discount,
      shipping: o.shipping,
      paymentFee: o.paymentFee,
      productCost: o.productCost,
      packagingCost: o.packagingCost,
      expectedReturnCost: o.expectedReturnCost,
      expectedRtoCost: o.expectedRtoCost,
      estimatedProfit: o.estimatedProfit,
      realisedProfit: o.realisedProfit,
      notes: o.notes,
      trackingNumber: o.trackingNumber,
      courierName: o.courierName,
      customer: o.customer,
      items: o.items,
      evidenceList: updatedEvidence,
      createdAt: o.createdAt,
      updatedAt: DateTime.now(),
    );

    _controller.add(List.from(_orders));
  }
}

final orderRepositoryProvider = Provider<IOrderRepository>((ref) {
  return MockOrderRepository();
});
