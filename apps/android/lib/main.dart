import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/paise_currency.dart';
import 'core/profit_engine/profit_calculator.dart';

import 'package:go_router/go_router.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/auth_notifier.dart';
import 'features/onboarding/data/onboarding_repository.dart';
import 'features/orders/presentation/order_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: QwentonCommerceOpsApp()));
}

class QwentonCommerceOpsApp extends ConsumerWidget {
  const QwentonCommerceOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Qwenton CommerceOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
      ],
    );
  }
}

/// Initial Dashboard Demo Screen displaying real-time profit cards and seed metrics
class DashboardDemoScreen extends ConsumerStatefulWidget {
  const DashboardDemoScreen({super.key});

  @override
  ConsumerState<DashboardDemoScreen> createState() => _DashboardDemoScreenState();
}

class _DashboardDemoScreenState extends ConsumerState<DashboardDemoScreen> {
  // Demo State: Pink Kurti pricing calculation
  int sellingPrice = 99900; // ₹999
  int discount = 5000;      // ₹50
  int productCost = 32000;  // ₹320
  int packagingCost = 2500; // ₹25
  int shippingCost = 7000;  // ₹70

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);
    final businessName = business?.name ?? 'Chikankari Studio Jaipur';

    final orderState = ref.watch(orderNotifierProvider);

    final profitResult = ProfitEngine.calculateEstimatedProfit(
      sellingPriceMinor: sellingPrice,
      discountMinor: discount,
      productCostMinor: productCost,
      packagingCostMinor: packagingCost,
      shippingCostMinor: shippingCost,
      paymentFeeRate: 0.0200,
      expectedReturnRate: 5.0,
      expectedRtoRate: 10.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qwenton CommerceOps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Storefront Link',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storefront link copied: qwenton.store/p/chikankari-pink')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & CSV Exports',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Header
            Text(
              businessName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Live Operations & True-Profit Dashboard',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 14),

            // Quick Operations Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/products'),
                    icon: const Icon(Icons.inventory_2_outlined, size: 16),
                    label: const Text('Products'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/orders'),
                    icon: const Icon(Icons.receipt_long_outlined, size: 16),
                    label: Text('Orders (${orderState.allOrders.length})'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/products/add'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top Metric Cards Row
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: "Active Orders",
                    value: "${orderState.allOrders.length} Orders",
                    subtitle: "Tap to Manage",
                    color: Colors.blue.shade50,
                    textColor: Colors.blue.shade900,
                    onTap: () => context.push('/orders'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: "Pending Payment",
                    value: "${orderState.needsReviewCount} Orders",
                    subtitle: "Needs Review",
                    color: Colors.amber.shade50,
                    textColor: Colors.amber.shade900,
                    onTap: () {
                      ref.read(orderNotifierProvider.notifier).setFilter('needs_review');
                      context.push('/orders');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // True Net Profit Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: profitResult.isProfitable ? Colors.emerald.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: profitResult.isProfitable ? Colors.emerald.shade300 : Colors.red.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimated True Profit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.emerald.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${profitResult.contributionMarginPercent}% Margin',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profitResult.estimatedProfit.toFormattedRupees(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: profitResult.isProfitable ? Colors.emerald.shade900 : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _CostLine(label: 'Net Sales Revenue', amount: profitResult.netSales.toFormattedRupees(), isPositive: true),
                  _CostLine(label: '(-) Product Cost (COGS)', amount: '-${profitResult.productCost.toFormattedRupees()}'),
                  _CostLine(label: '(-) Packaging Overhead', amount: '-${profitResult.packagingCost.toFormattedRupees()}'),
                  _CostLine(label: '(-) Shipping Allowance', amount: '-${profitResult.shippingCost.toFormattedRupees()}'),
                  _CostLine(label: '(-) Gateway / UPI Fee (2%)', amount: '-${profitResult.paymentFee.toFormattedRupees()}'),
                  _CostLine(label: '(-) Expected Return Reserve (5%)', amount: '-${profitResult.expectedReturnCost.toFormattedRupees()}'),
                  _CostLine(label: '(-) Expected RTO Provision (10%)', amount: '-${profitResult.expectedRtoCost.toFormattedRupees()}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostLine extends StatelessWidget {
  final String label;
  final String amount;
  final bool isPositive;

  const _CostLine({
    required this.label,
    required this.amount,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
}

// Emerald color helper extension
extension on Colors {
  static const MaterialColor emerald = MaterialColor(0xFF10B981, {
    50: Color(0xFFECFDF5),
    100: Color(0xFFD1FAE5),
    200: Color(0xFFA7F3D0),
    300: Color(0xFF6EE7B7),
    400: Color(0xFF34D399),
    500: Color(0xFF10B981),
    600: Color(0xFF059669),
    700: Color(0xFF047857),
    800: Color(0xFF065F46),
    900: Color(0xFF064E3B),
  });
}
