import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../../orders/presentation/order_notifier.dart';
import '../../products/presentation/product_notifier.dart';
import '../data/csv_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _exportOrders() async {
    final orders = ref.read(orderNotifierProvider).allOrders;
    final csvData = CsvService.exportOrdersToCsv(orders);

    await Share.share(
      csvData,
      subject: 'Qwenton_Orders_Export_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
    );
  }

  void _exportProducts() async {
    final products = ref.read(productNotifierProvider).allProducts;
    final csvData = CsvService.exportProductsToCsv(products);

    await Share.share(
      csvData,
      subject: 'Qwenton_Products_Catalogue_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
    );
  }

  void _copyImportTemplate() {
    final template = CsvService.generateSampleProductImportTemplate();
    Clipboard.setData(ClipboardData(text: template));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product CSV import template copied to clipboard!')),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'Under the Digital Personal Data Protection (DPDP) Act India 2023:\n\n'
          'Deleting your account will permanently purge all your business records, product catalogues, '
          'customer phone numbers, addresses, and payment evidence. This action is irreversible.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account and associated customer records purged.')),
                );
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Permanent Deletion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);
    final user = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Compliance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Profile Card
            _buildSectionHeader('Business Profile & Team'),
            const SizedBox(height: 8),
            Container(
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
                      Text(
                        business?.name ?? 'Store Name',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Role: Owner', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('WhatsApp: ${business?.whatsappNumber ?? "+91 98765 43210"}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  Text('Language: ${business?.preferredLanguage == "hi" ? "हिंदी (Hindi)" : "English (EN)"}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text('Default Shipping Cost: ${business?.defaultShippingCost.toFormattedRupees()}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('Default Packaging Overhead: ${business?.defaultPackagingCost.toFormattedRupees()}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('Return Benchmark: ${business?.defaultReturnRate}%  •  RTO Benchmark: ${business?.defaultRtoRate}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CSV & Accounting Operations
            _buildSectionHeader('Accounting & CSV Operations'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined, color: Colors.blue),
                    title: const Text('Export Orders to CSV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tally / Excel compatible with full profit audit columns', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: _exportOrders,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: Colors.indigo),
                    title: const Text('Export Product Catalogue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Backup pricing, SKU, and unit cost breakdowns', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: _exportProducts,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined, color: Colors.teal),
                    title: const Text('Copy Product Import Template', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Template headers for bulk product listing', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.copy, size: 16),
                    onTap: _copyImportTemplate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & Compliance (DPDP Act India 2023)
            _buildSectionHeader('Privacy & DPDP Compliance'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: Colors.emerald),
                    title: const Text('Export All Stored Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Download full JSON archive of business and order records', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.download, size: 16),
                    onTap: _exportOrders,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    title: const Text('Delete Account & Purge Customer Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                    subtitle: const Text('Permanently purges customer PII and operational tables', style: TextStyle(fontSize: 12)),
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sign Out
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out of Account'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),

            // Version Tag
            Center(
              child: Text(
                'Qwenton CommerceOps v1.0.0 (Build 20261019)\nAndroid-First True Profit Engine',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }
}
