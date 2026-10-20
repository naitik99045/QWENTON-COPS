import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/product.dart';
import '../../../core/profit_engine/profit_calculator.dart';
import '../../../core/utils/paise_currency.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../data/product_repository.dart';
import 'product_notifier.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? existingProduct;

  const AddEditProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _discountController;
  late TextEditingController _cogsController;
  late TextEditingController _packagingController;
  late TextEditingController _shippingController;
  late TextEditingController _stockController;

  double _expectedReturnRate = 5.0;
  double _expectedRtoRate = 10.0;
  bool _isLoading = false;

  final List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    final business = ref.read(currentBusinessProvider);

    final defaultShipping = business?.defaultShippingCost.toRupees().toStringAsFixed(0) ?? '70';
    final defaultPackaging = business?.defaultPackagingCost.toRupees().toStringAsFixed(0) ?? '25';
    _expectedReturnRate = business?.defaultReturnRate ?? 5.0;
    _expectedRtoRate = business?.defaultRtoRate ?? 10.0;

    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _sellingPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toRupees().toStringAsFixed(0) : '999',
    );
    _discountController = TextEditingController(
      text: p != null ? p.discount.toRupees().toStringAsFixed(0) : '0',
    );
    _cogsController = TextEditingController(
      text: p != null ? p.productCost.toRupees().toStringAsFixed(0) : '350',
    );
    _packagingController = TextEditingController(
      text: p != null ? p.packagingCost.toRupees().toStringAsFixed(0) : defaultPackaging,
    );
    _shippingController = TextEditingController(
      text: p != null ? p.shippingCost.toRupees().toStringAsFixed(0) : defaultShipping,
    );
    _stockController = TextEditingController(
      text: p != null ? p.stockQuantity.toString() : '25',
    );

    if (p != null) {
      _variants.addAll(p.variants);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _sellingPriceController.dispose();
    _discountController.dispose();
    _cogsController.dispose();
    _packagingController.dispose();
    _shippingController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  EstimatedProfitResult _calculateCurrentProfit() {
    final selling = (double.tryParse(_sellingPriceController.text.trim()) ?? 0.0) * 100;
    final discount = (double.tryParse(_discountController.text.trim()) ?? 0.0) * 100;
    final cogs = (double.tryParse(_cogsController.text.trim()) ?? 0.0) * 100;
    final packaging = (double.tryParse(_packagingController.text.trim()) ?? 0.0) * 100;
    final shipping = (double.tryParse(_shippingController.text.trim()) ?? 0.0) * 100;

    return ProfitEngine.calculateEstimatedProfit(
      sellingPriceMinor: selling.round(),
      discountMinor: discount.round(),
      productCostMinor: cogs.round(),
      packagingCostMinor: packaging.round(),
      shippingCostMinor: shipping.round(),
      paymentFeeRate: 0.0200,
      expectedReturnRate: _expectedReturnRate,
      expectedRtoRate: _expectedRtoRate,
    );
  }

  void _addVariantPrompt() {
    final variantNameController = TextEditingController();
    final variantStockController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product Variant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: variantNameController,
              decoration: const InputDecoration(labelText: 'Variant Name (e.g. Size M, Red)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: variantStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (variantNameController.text.trim().isNotEmpty) {
                setState(() {
                  _variants.add(ProductVariant(
                    id: 'var_${DateTime.now().millisecondsSinceEpoch}',
                    productId: '',
                    name: variantNameController.text.trim(),
                    stockQuantity: int.tryParse(variantStockController.text.trim()) ?? 10,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final selling = ((double.tryParse(_sellingPriceController.text.trim()) ?? 0.0) * 100).round();
    final discount = ((double.tryParse(_discountController.text.trim()) ?? 0.0) * 100).round();
    final cogs = ((double.tryParse(_cogsController.text.trim()) ?? 0.0) * 100).round();
    final packaging = ((double.tryParse(_packagingController.text.trim()) ?? 0.0) * 100).round();
    final shipping = ((double.tryParse(_shippingController.text.trim()) ?? 0.0) * 100).round();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    final notifier = ref.read(productNotifierProvider.notifier);
    await notifier.addProduct(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      sku: _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null,
      sellingPriceMinor: selling,
      discountMinor: discount,
      productCostMinor: cogs,
      packagingCostMinor: packaging,
      shippingCostMinor: shipping,
      paymentFeeRate: 0.0200,
      expectedReturnRate: _expectedReturnRate,
      expectedRtoRate: _expectedRtoRate,
      stockQuantity: stock,
      variants: _variants,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product published and storefront link activated!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profit = _calculateCurrentProfit();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProduct != null ? 'Edit Product' : 'Add New Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Basic Details
                _sectionHeader('1. Product Information'),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Title *',
                    hintText: 'e.g. Hand Embroidered Chikankari Kurti',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Product title is required' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU (Optional)',
                          hintText: 'CHK-PK-01',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Units *',
                          hintText: '45',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter stock count' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description for Customer Storefront',
                    hintText: 'Mention fabric, sizes, and care instructions...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Financials & Cost Structure
                _sectionHeader('2. Price & Cost Structure'),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Price is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discount (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cogsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Product Cost (COGS) (₹) *',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Cost is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _packagingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Packaging (₹)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _shippingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Courier Shipping Cost (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // 3. LIVE TRUE-PROFIT CALCULATOR PREVIEW WIDGET
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: profit.isProfitable ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: profit.isProfitable ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                profit.isProfitable ? Icons.trending_up : Icons.warning_amber_rounded,
                                color: profit.isProfitable ? const Color(0xFF047857) : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Live Profit per Unit Sold',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Text(
                            '${profit.contributionMarginPercent}% Margin',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: profit.isProfitable ? const Color(0xFF047857) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profit.estimatedProfit.toFormattedRupees(),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: profit.isProfitable ? const Color(0xFF065F46) : Colors.red.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profit.isProfitable
                            ? 'After COGS, packing, courier shipping, 2% PG fee, and 10% RTO provision.'
                            : 'Caution: At this pricing, you will lose money on every order due to shipping & packaging!',
                        style: TextStyle(
                          fontSize: 12,
                          color: profit.isProfitable ? const Color(0xFF065F46) : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Variants Builder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionHeader('3. Product Variants (${_variants.length})'),
                    TextButton.icon(
                      onPressed: _addVariantPrompt,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Variant'),
                    ),
                  ],
                ),
                if (_variants.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'No variants added (e.g. Size M, L, XL). Tap "Add Variant" if your product has options.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: _variants.map((v) {
                      return Chip(
                        label: Text('${v.name} (${v.stockQuantity} in stock)'),
                        onDeleted: () {
                          setState(() {
                            _variants.remove(v);
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Publish Product & Activate Storefront Link'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }
}
