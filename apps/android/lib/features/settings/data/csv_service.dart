import 'package:csv/csv.dart';
import '../../../core/models/order.dart';
import '../../../core/models/product.dart';

class CsvService {
  /// Exports all orders into RFC 4180 compliant CSV format.
  /// Matches dashboard financial figures to the exact Paisa and Rupee.
  static String exportOrdersToCsv(List<Order> orders) {
    final List<List<dynamic>> rows = [
      // CSV Header Row
      [
        'Order Number',
        'Date & Time',
        'Customer Name',
        'Customer Phone',
        'Delivery Address',
        'Pincode',
        'City',
        'State',
        'Payment Method',
        'Payment Status',
        'Fulfilment Status',
        'Subtotal (₹)',
        'Discount (₹)',
        'Net Revenue (₹)',
        'Product Cost / COGS (₹)',
        'Packaging Overhead (₹)',
        'Courier Shipping (₹)',
        'Payment Fee (₹)',
        'Estimated Profit (₹)',
        'Realised Profit (₹)',
        'Courier Partner',
        'Tracking Number',
      ],
    ];

    for (final o in orders) {
      final c = o.customer;
      rows.add([
        o.orderNumber,
        o.createdAt.toIso8601String(),
        c?.name ?? '',
        c?.phone ?? '',
        c?.address ?? '',
        c?.pincode ?? '',
        c?.city ?? '',
        c?.state ?? '',
        o.paymentMethod.name.toUpperCase(),
        o.paymentStatus.name,
        o.fulfilmentStatus.displayName,
        o.subtotal.toRupees().toStringAsFixed(2),
        o.discount.toRupees().toStringAsFixed(2),
        o.netSales.toRupees().toStringAsFixed(2),
        o.productCost.toRupees().toStringAsFixed(2),
        o.packagingCost.toRupees().toStringAsFixed(2),
        o.shipping.toRupees().toStringAsFixed(2),
        o.paymentFee.toRupees().toStringAsFixed(2),
        o.estimatedProfit.toRupees().toStringAsFixed(2),
        o.realisedProfit != null ? o.realisedProfit!.toRupees().toStringAsFixed(2) : 'N/A',
        o.courierName ?? '',
        o.trackingNumber ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports products into CSV format for accounting and catalogue backups
  static String exportProductsToCsv(List<Product> products) {
    final List<List<dynamic>> rows = [
      [
        'SKU',
        'Product Name',
        'Selling Price (₹)',
        'Discount (₹)',
        'Net Price (₹)',
        'Product Cost / COGS (₹)',
        'Packaging Cost (₹)',
        'Shipping Cost (₹)',
        'Stock Quantity',
        'Status',
      ],
    ];

    for (final p in products) {
      rows.add([
        p.sku ?? '',
        p.name,
        p.sellingPrice.toRupees().toStringAsFixed(2),
        p.discount.toRupees().toStringAsFixed(2),
        p.netPrice.toRupees().toStringAsFixed(2),
        p.productCost.toRupees().toStringAsFixed(2),
        p.packagingCost.toRupees().toStringAsFixed(2),
        p.shippingCost.toRupees().toStringAsFixed(2),
        p.stockQuantity,
        p.isActive ? 'Active' : 'Inactive',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates a starter template CSV string for bulk product imports
  static String generateSampleProductImportTemplate() {
    final List<List<dynamic>> sampleRows = [
      [
        'SKU',
        'Product Name',
        'Selling Price (₹)',
        'Product Cost / COGS (₹)',
        'Packaging Cost (₹)',
        'Shipping Cost (₹)',
        'Stock Quantity',
      ],
      [
        'CHK-BL-01',
        'Chikankari Kurti - Sky Blue',
        '999.00',
        '320.00',
        '25.00',
        '70.00',
        '50',
      ],
      [
        'ANR-RD-02',
        'Cotton Anarkali Set - Crimson Red',
        '1499.00',
        '520.00',
        '30.00',
        '80.00',
        '30',
      ],
    ];

    return const ListToCsvConverter().convert(sampleRows);
  }
}
