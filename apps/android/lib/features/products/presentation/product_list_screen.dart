import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/profit_engine/profit_calculator.dart';
import '../../storefront/presentation/share_link_dialog.dart';
import '../data/product_repository.dart';
import 'product_notifier.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productNotifierProvider);
    final notifier = ref.read(productNotifierProvider.notifier);
    final products = state.filteredProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalogue'),
        actions: [
          IconButton(
            icon: Icon(
              state.filterActiveOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: state.filterActiveOnly ? Colors.blue : null,
            ),
            tooltip: 'Filter Active Only',
            onPressed: () => notifier.toggleFilterActiveOnly(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) => notifier.setSearchQuery(val),
            ),
          ),

          // Product List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No products found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.push('/products/add'),
                              child: const Text('Create First Product'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadProducts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            final profit = ProfitEngine.calculateEstimatedProfit(
                              sellingPriceMinor: p.sellingPrice.value,
                              discountMinor: p.discount.value,
                              productCostMinor: p.productCost.value,
                              packagingCostMinor: p.packagingCost.value,
                              shippingCostMinor: p.shippingCost.value,
                              paymentFeeRate: p.paymentFeeRate,
                              expectedReturnRate: p.expectedReturnRate,
                              expectedRtoRate: p.expectedRtoRate,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Thumbnail
                                        Container(
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(10),
                                            image: p.imageUrls.isNotEmpty
                                                ? DecorationImage(
                                                    image: NetworkImage(p.imageUrls.first),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: p.imageUrls.isEmpty
                                              ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey)
                                              : null,
                                        ),
                                        const SizedBox(width: 14),

                                        // Product Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                p.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'SKU: ${p.sku ?? "N/A"}  •  ${p.stockQuantity} in stock',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(
                                                    p.sellingPrice.toFormattedRupees(),
                                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                                  ),
                                                  if (p.discount.value > 0) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      p.netPrice.toFormattedRupees(),
                                                      style: TextStyle(
                                                        decoration: TextDecoration.lineThrough,
                                                        color: Colors.grey[500],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    // Margin Badge & Share Link Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // True Profit Margin Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: profit.isProfitable
                                                ? const Color(0xFFECFDF5)
                                                : const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: profit.isProfitable
                                                  ? const Color(0xFFA7F3D0)
                                                  : const Color(0xFFFECACA),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                profit.isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                                                size: 14,
                                                color: profit.isProfitable ? const Color(0xFF047857) : Colors.red,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Profit: ${profit.estimatedProfit.toFormattedRupees()} (${profit.contributionMarginPercent}%)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: profit.isProfitable ? const Color(0xFF047857) : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Action buttons
                                        Row(
                                          children: [
                                            // Share Link Button
                                            IconButton(
                                              icon: const Icon(Icons.share_outlined, color: Colors.blue, size: 20),
                                              tooltip: 'Share Storefront Link',
                                              onPressed: () async {
                                                final repo = ref.read(productRepositoryProvider);
                                                final url = await repo.generateStorefrontLink(p.id);
                                                if (context.mounted) {
                                                  ShareLinkDialog.show(context, p, url);
                                                }
                                              },
                                            ),
                                            // Active switch
                                            Switch(
                                              value: p.isActive,
                                              activeColor: Colors.blue,
                                              onChanged: (val) {
                                                notifier.toggleProductActive(p.id, val);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
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
}
