import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/order.dart';
import '../../../core/models/payment_evidence.dart';
import 'order_notifier.dart';

class OrderFeedScreen extends ConsumerWidget {
  const OrderFeedScreen({super.key});

  void _sendWhatsAppMessage(BuildContext context, Order order) async {
    final customer = order.customer;
    if (customer == null || customer.phone.isEmpty) return;

    final phoneDigits = customer.phone.replaceAll(RegExp(r'\D'), '');
    final text = Uri.encodeComponent(
      'Namaste ${customer.name}! Thank you for ordering with us.\n'
      'Order: #${order.orderNumber}\n'
      'Status: ${order.fulfilmentStatus.displayName}\n'
      'Total: ${order.netSales.toFormattedRupees()}',
    );

    final uri = Uri.parse('whatsapp://send?phone=$phoneDigits&text=$text');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse('https://wa.me/$phoneDigits?text=$text'), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderNotifierProvider);
    final notifier = ref.read(orderNotifierProvider.notifier);
    final orders = state.filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: () => notifier.loadOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search order #, customer name, phone...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => notifier.setSearchQuery(val),
            ),
          ),

          // Filter Chips Horizontal Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'all', 'All (${state.allOrders.length})', state.activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  'needs_review',
                  'Needs Review (${state.needsReviewCount})',
                  state.activeFilter,
                  isWarning: state.needsReviewCount > 0,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'to_pack', 'To Pack (${state.toPackCount})', state.activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, ref, 'shipped', 'Shipped (${state.shippedCount})', state.activeFilter),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  ref,
                  'rto',
                  'RTO (${state.rtoCount})',
                  state.activeFilter,
                  isDestructive: state.rtoCount > 0,
                ),
              ],
            ),
          ),

          // Orders Feed List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text('No orders in this view', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final o = orders[index];
                            final hasEvidence = o.evidenceList.isNotEmpty;
                            final isRto = o.fulfilmentStatus == FulfilmentStatus.rto;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isRto
                                      ? Colors.red.shade300
                                      : o.hasEvidenceAwaitingReview
                                          ? Colors.amber.shade300
                                          : Colors.grey.shade200,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.push('/orders/${o.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Order Header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            o.orderNumber,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          _buildFulfilmentBadge(o.fulfilmentStatus),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Customer & Location
                                      Text(
                                        '${o.customer?.name ?? "Customer"}  •  ${o.customer?.city ?? "India"}',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 10),

                                      // Financial Breakdown Summary
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order Total',
                                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                              ),
                                              Text(
                                                o.netSales.toFormattedRupees(),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                isRto ? 'Realised Loss' : (o.realisedProfit != null ? 'Realised Profit' : 'Estimated Profit'),
                                                style: TextStyle(
                                                  color: isRto ? Colors.red : Colors.grey[500],
                                                  fontSize: 11,
                                                ),
                                              ),
                                              Text(
                                                (o.realisedProfit ?? o.estimatedProfit).toFormattedRupees(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                  color: isRto ? Colors.red.shade800 : Colors.emerald.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Payment Status & Evidence Flag
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _buildPaymentBadge(o.paymentMethod, o.paymentStatus),
                                          if (hasEvidence && o.hasEvidenceAwaitingReview) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.amber.shade400),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.image_outlined, size: 12, color: Colors.amber.shade900),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Evidence: Needs Review',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.amber.shade900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),

                                      // Quick Action Buttons
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _sendWhatsAppMessage(context, o),
                                            icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF25D366)),
                                            label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF0F5132))),
                                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                          ),
                                          TextButton(
                                            onPressed: () => context.push('/orders/${o.id}'),
                                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                            child: const Row(
                                              children: [
                                                Text('View Details'),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_ios, size: 12),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String filterValue,
    String label,
    String currentFilter, {
    bool isWarning = false,
    bool isDestructive = false,
  }) {
    final isSelected = currentFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: isDestructive
          ? Colors.red.shade100
          : isWarning
              ? Colors.amber.shade100
              : Colors.blue.shade100,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isDestructive
            ? Colors.red.shade900
            : isWarning
                ? Colors.amber.shade900
                : (isSelected ? Colors.blue.shade900 : Colors.black87),
      ),
      onSelected: (_) => ref.read(orderNotifierProvider.notifier).setFilter(filterValue),
    );
  }

  Widget _buildFulfilmentBadge(FulfilmentStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case FulfilmentStatus.delivered:
      case FulfilmentStatus.paid:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        break;
      case FulfilmentStatus.rto:
      case FulfilmentStatus.returned:
      case FulfilmentStatus.cancelled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFB91C1C);
        break;
      case FulfilmentStatus.paymentPending:
      case FulfilmentStatus.newOrder:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        break;
      case FulfilmentStatus.packed:
      case FulfilmentStatus.shipped:
      case FulfilmentStatus.codConfirmed:
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildPaymentBadge(PaymentMethod method, PaymentStatus status) {
    final isCod = method == PaymentMethod.cod;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCod ? Colors.purple.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isCod ? Colors.purple.shade200 : Colors.blue.shade200),
      ),
      child: Text(
        isCod ? 'COD' : 'UPI',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isCod ? Colors.purple.shade900 : Colors.blue.shade900,
        ),
      ),
    );
  }
}
