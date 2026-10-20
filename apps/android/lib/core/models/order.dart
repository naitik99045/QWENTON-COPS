import '../utils/paise_currency.dart';
import 'customer.dart';
import 'payment_evidence.dart';

enum PaymentMethod { upi, cod }

enum PaymentStatus { pending, paid, codConfirmed, refunded, failed }

enum FulfilmentStatus {
  newOrder,
  paymentPending,
  paid,
  codConfirmed,
  packed,
  shipped,
  delivered,
  returnRequested,
  returned,
  rto,
  cancelled,
  refunded;

  String get displayName {
    switch (this) {
      case FulfilmentStatus.newOrder:
        return 'New';
      case FulfilmentStatus.paymentPending:
        return 'Payment Pending';
      case FulfilmentStatus.paid:
        return 'Paid';
      case FulfilmentStatus.codConfirmed:
        return 'COD Confirmed';
      case FulfilmentStatus.packed:
        return 'Packed';
      case FulfilmentStatus.shipped:
        return 'Shipped';
      case FulfilmentStatus.delivered:
        return 'Delivered';
      case FulfilmentStatus.returnRequested:
        return 'Return Requested';
      case FulfilmentStatus.returned:
        return 'Returned';
      case FulfilmentStatus.rto:
        return 'RTO (Failed Delivery)';
      case FulfilmentStatus.cancelled:
        return 'Cancelled';
      case FulfilmentStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isTerminal =>
      this == FulfilmentStatus.delivered ||
      this == FulfilmentStatus.returned ||
      this == FulfilmentStatus.rto ||
      this == FulfilmentStatus.cancelled ||
      this == FulfilmentStatus.refunded;
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String? variantId;
  final int quantity;
  final Paise unitPrice;
  final Paise unitCost;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: Paise(json['unit_price_minor'] as int),
      unitCost: Paise(json['unit_cost_minor'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price_minor': unitPrice.value,
      'unit_cost_minor': unitCost.value,
    };
  }
}

class Order {
  final String id;
  final String businessId;
  final String customerId;
  final String orderNumber; // e.g. QC-20261018-0001
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final FulfilmentStatus fulfilmentStatus;

  // Financial components (Paise)
  final Paise subtotal;
  final Paise discount;
  final Paise shipping;
  final Paise paymentFee;
  final Paise productCost;
  final Paise packagingCost;
  final Paise expectedReturnCost;
  final Paise expectedRtoCost;
  final Paise estimatedProfit;
  final Paise? realisedProfit;

  final String? notes;
  final String? trackingNumber;
  final String? courierName;
  final Customer? customer;
  final List<OrderItem> items;
  final List<PaymentEvidence> evidenceList;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.orderNumber,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.fulfilmentStatus = FulfilmentStatus.newOrder,
    required this.subtotal,
    this.discount = const Paise(0),
    this.shipping = const Paise(0),
    this.paymentFee = const Paise(0),
    required this.productCost,
    this.packagingCost = const Paise(0),
    this.expectedReturnCost = const Paise(0),
    this.expectedRtoCost = const Paise(0),
    required this.estimatedProfit,
    this.realisedProfit,
    this.notes,
    this.trackingNumber,
    this.courierName,
    this.customer,
    this.items = const [],
    this.evidenceList = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Paise get netSales => subtotal - discount;

  bool get hasEvidenceAwaitingReview =>
      evidenceList.any((e) => e.reviewStatus == ReviewStatus.needsReview);

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      customerId: json['customer_id'] as String,
      orderNumber: json['order_number'] as String,
      paymentMethod: (json['payment_method'] as String).toLowerCase() == 'cod'
          ? PaymentMethod.cod
          : PaymentMethod.upi,
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String? ?? 'pending'),
      fulfilmentStatus: _parseFulfilmentStatus(json['fulfilment_status'] as String? ?? 'new'),
      subtotal: Paise(json['subtotal_minor'] as int),
      discount: Paise(json['discount_minor'] as int? ?? 0),
      shipping: Paise(json['shipping_minor'] as int? ?? 0),
      paymentFee: Paise(json['payment_fee_minor'] as int? ?? 0),
      productCost: Paise(json['product_cost_minor'] as int),
      packagingCost: Paise(json['packaging_cost_minor'] as int? ?? 0),
      expectedReturnCost: Paise(json['expected_return_cost_minor'] as int? ?? 0),
      expectedRtoCost: Paise(json['expected_rto_cost_minor'] as int? ?? 0),
      estimatedProfit: Paise(json['estimated_profit_minor'] as int),
      realisedProfit: json['realised_profit_minor'] != null
          ? Paise(json['realised_profit_minor'] as int)
          : null,
      notes: json['notes'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      courierName: json['courier_name'] as String?,
      customer: json['customer'] != null ? Customer.fromJson(json['customer'] as Map<String, dynamic>) : null,
      items: (json['order_items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      evidenceList: (json['payment_evidence'] as List<dynamic>?)
              ?.map((ev) => PaymentEvidence.fromJson(ev as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'cod_confirmed':
        return PaymentStatus.codConfirmed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }

  static FulfilmentStatus _parseFulfilmentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'payment_pending':
        return FulfilmentStatus.paymentPending;
      case 'paid':
        return FulfilmentStatus.paid;
      case 'cod_confirmed':
        return FulfilmentStatus.codConfirmed;
      case 'packed':
        return FulfilmentStatus.packed;
      case 'shipped':
        return FulfilmentStatus.shipped;
      case 'delivered':
        return FulfilmentStatus.delivered;
      case 'return_requested':
        return FulfilmentStatus.returnRequested;
      case 'returned':
        return FulfilmentStatus.returned;
      case 'rto':
        return FulfilmentStatus.rto;
      case 'cancelled':
        return FulfilmentStatus.cancelled;
      case 'refunded':
        return FulfilmentStatus.refunded;
      case 'new':
      default:
        return FulfilmentStatus.newOrder;
    }
  }
}
