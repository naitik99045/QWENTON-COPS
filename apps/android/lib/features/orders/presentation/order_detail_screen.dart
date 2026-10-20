import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/order.dart';
import '../../../core/models/payment_evidence.dart';
import '../../../core/utils/paise_currency.dart';
import '../../communication/presentation/whatsapp_action_sheet.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/order_repository.dart';
import 'order_notifier.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  void _openTrackingDialog(Order order) {
    final courierController = TextEditingController(text: order.courierName ?? 'Delhivery');
    final trackingController = TextEditingController(text: order.trackingNumber ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Courier Tracking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courierController,
              decoration: const InputDecoration(labelText: 'Courier Partner (e.g. Delhivery, BlueDart)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(labelText: 'AWB / Tracking Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (trackingController.text.trim().isNotEmpty) {
                ref.read(orderNotifierProvider.notifier).updateOrderStatus(
                  order.id,
                  FulfilmentStatus.shipped,
                  courierName: courierController.text.trim(),
                  trackingNumber: trackingController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save & Mark Shipped'),
          ),
        ],
      ),
    );
  }

  void _openEditCostsDialog(Order order) {
    final cogsController = TextEditingController(text: order.productCost.toRupees().toStringAsFixed(0));
    final packagingController = TextEditingController(text: order.packagingCost.toRupees().toStringAsFixed(0));
    final shippingController = TextEditingController(text: order.shipping.toRupees().toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust Order Costs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cogsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Product Cost (COGS) (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: packagingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Actual Packaging Cost (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: shippingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Actual Shipping Paid (₹)', prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final cogs = (double.tryParse(cogsController.text.trim()) ?? 0.0) * 100;
              final packaging = (double.tryParse(packagingController.text.trim()) ?? 0.0) * 100;
              final shipping = (double.tryParse(shippingController.text.trim()) ?? 0.0) * 100;

              ref.read(orderNotifierProvider.notifier).updateCostAssumptions(
                order.id,
                productCostMinor: cogs.round(),
                packagingCostMinor: packaging.round(),
                shippingMinor: shipping.round(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Recalculate Profit'),
          ),
        ],
      ),
    );
  }

  void _sendWhatsApp(String phone, String text) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('whatsapp://send?phone=$digits&text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderNotifierProvider);
    final order = state.allOrders.cast<Order?>().firstWhere(
          (o) => o?.id == widget.orderId,
          orElse: () => null,
        );

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final customer = order.customer;
    final business = ref.watch(currentBusinessProvider);
    final businessName = business?.name ?? 'Our Store';
    final isRto = order.fulfilmentStatus == FulfilmentStatus.rto;
    final isDelivered = order.fulfilmentStatus == FulfilmentStatus.delivered;

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
            tooltip: 'WhatsApp Action Center',
            onPressed: () => WhatsAppActionSheet.show(context, order, businessName),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Pipeline Bar
            _buildStatusCard(order),
            const SizedBox(height: 16),

            // Customer Contact Card
            _buildCustomerCard(order),
            const SizedBox(height: 16),

            // True Profit Breakdown Card
            _buildProfitCard(order),
            const SizedBox(height: 16),

            // Payment Evidence Card (if any)
            if (order.evidenceList.isNotEmpty) ...[
              _buildEvidenceCard(order),
              const SizedBox(height: 16),
            ],

            // Action Buttons Bar
            _buildOrderActions(order),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Status', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                order.fulfilmentStatus.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (order.trackingNumber != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order.courierName}: ${order.trackingNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Order order) {
    final c = order.customer;
    if (c == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customer & Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                    tooltip: 'WhatsApp Customer',
                    onPressed: () {
                      final biz = ref.read(currentBusinessProvider)?.name ?? 'Our Store';
                      WhatsAppActionSheet.show(context, order, biz);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, color: Colors.blue),
                    tooltip: 'Call Customer',
                    onPressed: () async {
                      final url = Uri.parse('tel:${c.phone}');
                      if (await canLaunchUrl(url)) launchUrl(url);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(c.phone, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '${c.address}, ${c.city ?? ""} - ${c.pincode}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(Order order) {
    final isRto = order.fulfilmentStatus == FulfilmentStatus.rto;
    final isDelivered = order.fulfilmentStatus == FulfilmentStatus.delivered;
    final profitDisplay = (order.realisedProfit ?? order.estimatedProfit);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRto ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRto ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRto ? 'True Realised Loss (RTO)' : (isDelivered ? 'True Realised Profit' : 'Estimated Net Profit'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Adjust Actual Incurred Costs',
                onPressed: () => _openEditCostsDialog(order),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profitDisplay.toFormattedRupees(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isRto ? Colors.red.shade900 : const Color(0xFF065F46),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          _lineItem('Net Order Revenue', order.netSales.toFormattedRupees(), isPositive: true),
          _lineItem('(-) Product Cost (COGS)', '-${order.productCost.toFormattedRupees()}'),
          _lineItem('(-) Packaging Overhead', '-${order.packagingCost.toFormattedRupees()}'),
          _lineItem('(-) Courier Shipping Paid', '-${order.shipping.toFormattedRupees()}'),
          _lineItem('(-) Gateway / UPI Fee', '-${order.paymentFee.toFormattedRupees()}'),
          if (!isDelivered && !isRto) ...[
            _lineItem('(-) Return Risk Provision', '-${order.expectedReturnCost.toFormattedRupees()}'),
            _lineItem('(-) RTO Logistics Buffer', '-${order.expectedRtoCost.toFormattedRupees()}'),
          ],
          if (isRto) ...[
            _lineItem('(-) Return Courier Penalty (2x)', '-${order.shipping.toFormattedRupees()}'),
          ],
        ],
      ),
    );
  }

  Widget _lineItem(String label, String amount, {bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.emerald.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(Order order) {
    final ev = order.evidenceList.first;
    final isNeedsReview = ev.reviewStatus == ReviewStatus.needsReview;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isNeedsReview ? Colors.amber.shade300 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isNeedsReview ? Colors.amber.shade50 : Colors.emerald.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isNeedsReview ? 'Needs Review' : 'Verified by Seller',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isNeedsReview ? Colors.amber.shade900 : Colors.emerald.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (ev.reference != null) ...[
            Text('UTR / Reference: ${ev.reference}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
          ],
          if (ev.storagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ev.storagePath!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: Colors.grey[100],
                  child: const Center(child: Text('Payment Screenshot Preview')),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (isNeedsReview) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(orderNotifierProvider.notifier).reviewEvidence(
                          order.id,
                          ev.id,
                          ReviewStatus.rejected,
                        ),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject Evidence'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(orderNotifierProvider.notifier).reviewEvidence(
                          order.id,
                          ev.id,
                          ReviewStatus.verifiedBySeller,
                        ),
                    child: const Text('Confirm & Verify'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    final notifier = ref.read(orderNotifierProvider.notifier);
    final status = order.fulfilmentStatus;

    return Column(
      children: [
        if (status == FulfilmentStatus.paymentPending || status == FulfilmentStatus.newOrder) ...[
          ElevatedButton(
            onPressed: () => notifier.updateOrderStatus(order.id, FulfilmentStatus.packed),
            child: const Text('Mark as Packed'),
          ),
        ] else if (status == FulfilmentStatus.packed || status == FulfilmentStatus.codConfirmed) ...[
          ElevatedButton(
            onPressed: () => _openTrackingDialog(order),
            child: const Text('Add Tracking & Mark Shipped'),
          ),
        ] else if (status == FulfilmentStatus.shipped) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.updateOrderStatus(order.id, FulfilmentStatus.rto),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Mark RTO (Doorstep Rejection)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => notifier.updateOrderStatus(order.id, FulfilmentStatus.delivered),
                  child: const Text('Mark Delivered'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
