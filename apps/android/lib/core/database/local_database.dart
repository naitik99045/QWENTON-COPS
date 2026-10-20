import 'package:drift/drift.dart';
import '../models/order.dart';
import '../models/product.dart';

// Drift Table definitions for offline resilience in Indian wholesale markets / low connectivity
class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get sku => text().nullable()();
  IntColumn get sellingPriceMinor => integer()();
  IntColumn get productCostMinor => integer()();
  IntColumn get packagingCostMinor => integer().withDefault(const Constant(0))();
  IntColumn get shippingCostMinor => integer().withDefault(const Constant(0))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedOrders extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get orderNumber => text()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerAddress => text().nullable()();
  TextColumn get customerPincode => text().nullable()();
  TextColumn get customerCity => text().nullable()();
  TextColumn get customerState => text().nullable()();
  TextColumn get paymentMethod => text()();
  TextColumn get paymentStatus => text()();
  TextColumn get fulfilmentStatus => text()();
  IntColumn get subtotalMinor => integer()();
  IntColumn get discountMinor => integer().withDefault(const Constant(0))();
  IntColumn get netSalesMinor => integer()();
  IntColumn get estimatedProfitMinor => integer()();
  IntColumn get realisedProfitMinor => integer().nullable()();
  TextColumn get courierName => text().nullable()();
  TextColumn get trackingNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OutboxQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()(); // e.g., 'update_status', 'update_costs', 'verify_evidence'
  TextColumn get targetEntityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))(); // pending, synced, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get lastError => text().nullable()();
}

/// In-memory & SQLite Drift offline cache representation
/// Enables sellers in low-connectivity market hubs (e.g. Chandni Chowk, Surat)
/// to review orders, check margins, and queue fulfillment operations without blocking.
class OfflineSyncRepository {
  final Map<String, CachedOrderData> _orderCache = {};
  final Map<String, CachedProductData> _productCache = {};
  final List<OutboxQueueItem> _outboxQueue = [];

  bool isOnline = true;

  void cacheOrder(Order order) {
    _orderCache[order.id] = CachedOrderData(
      id: order.id,
      businessId: order.businessId,
      orderNumber: order.orderNumber,
      customerName: order.customer?.name,
      customerPhone: order.customer?.phone,
      paymentMethod: order.paymentMethod.name,
      paymentStatus: order.paymentStatus.name,
      fulfilmentStatus: order.fulfilmentStatus.name,
      netSalesMinor: order.netSales.minorUnits,
      estimatedProfitMinor: order.estimatedProfit.minorUnits,
      realisedProfitMinor: order.realisedProfit?.minorUnits,
      courierName: order.courierName,
      trackingNumber: order.trackingNumber,
      createdAt: order.createdAt,
    );
  }

  void cacheProduct(Product product) {
    _productCache[product.id] = CachedProductData(
      id: product.id,
      businessId: product.businessId,
      name: product.name,
      sellingPriceMinor: product.sellingPrice.minorUnits,
      cogsMinor: product.productCost.minorUnits,
      stockQuantity: product.stockQuantity,
      updatedAt: product.updatedAt,
    );
  }

  /// Queues an operational action to the Outbox when network is unstable
  void queueAction({
    required String actionType,
    required String targetEntityId,
    required String payloadJson,
  }) {
    _outboxQueue.add(OutboxQueueItem(
      id: _outboxQueue.length + 1,
      actionType: actionType,
      targetEntityId: targetEntityId,
      payloadJson: payloadJson,
      createdAt: DateTime.now(),
      syncStatus: 'pending',
    ));
  }

  List<OutboxQueueItem> get pendingOutbox =>
      _outboxQueue.where((item) => item.syncStatus == 'pending').toList();

  int get pendingOutboxCount => pendingOutbox.length;

  void markSynced(int outboxId) {
    final idx = _outboxQueue.indexWhere((item) => item.id == outboxId);
    if (idx != -1) {
      final old = _outboxQueue[idx];
      _outboxQueue[idx] = OutboxQueueItem(
        id: old.id,
        actionType: old.actionType,
        targetEntityId: old.targetEntityId,
        payloadJson: old.payloadJson,
        createdAt: old.createdAt,
        syncStatus: 'synced',
      );
    }
  }
}

class CachedOrderData {
  final String id;
  final String businessId;
  final String orderNumber;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod;
  final String paymentStatus;
  final String fulfilmentStatus;
  final int netSalesMinor;
  final int estimatedProfitMinor;
  final int? realisedProfitMinor;
  final String? courierName;
  final String? trackingNumber;
  final DateTime createdAt;

  CachedOrderData({
    required this.id,
    required this.businessId,
    required this.orderNumber,
    this.customerName,
    this.customerPhone,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.fulfilmentStatus,
    required this.netSalesMinor,
    required this.estimatedProfitMinor,
    this.realisedProfitMinor,
    this.courierName,
    this.trackingNumber,
    required this.createdAt,
  });
}

class CachedProductData {
  final String id;
  final String businessId;
  final String name;
  final int sellingPriceMinor;
  final int cogsMinor;
  final int stockQuantity;
  final DateTime updatedAt;

  CachedProductData({
    required this.id,
    required this.businessId,
    required this.name,
    required this.sellingPriceMinor,
    required this.cogsMinor,
    required this.stockQuantity,
    required this.updatedAt,
  });
}

class OutboxQueueItem {
  final int id;
  final String actionType;
  final String targetEntityId;
  final String payloadJson;
  final DateTime createdAt;
  final String syncStatus;

  OutboxQueueItem({
    required this.id,
    required this.actionType,
    required this.targetEntityId,
    required this.payloadJson,
    required this.createdAt,
    required this.syncStatus,
  });
}
