import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/onboarding_repository.dart';

class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends ConsumerState<BusinessOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController(text: 'Chikankari Studio Jaipur');
  final _whatsappController = TextEditingController(text: '9876543210');
  final _gstinController = TextEditingController();
  final _shippingCostController = TextEditingController(text: '70');
  final _packagingCostController = TextEditingController(text: '25');

  String _preferredLanguage = 'hi'; // 'en' or 'hi'
  double _expectedReturnRate = 5.0; // 5%
  double _expectedRtoRate = 10.0;    // 10%
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _whatsappController.dispose();
    _gstinController.dispose();
    _shippingCostController.dispose();
    _packagingCostController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authUser = ref.read(authNotifierProvider).user;
    final userId = authUser?.id ?? '00000000-0000-0000-0000-000000000001';

    final shippingRupees = double.tryParse(_shippingCostController.text.trim()) ?? 70.0;
    final packagingRupees = double.tryParse(_packagingCostController.text.trim()) ?? 25.0;

    final repo = ref.read(onboardingRepositoryProvider);
    final business = await repo.createBusiness(
      ownerUserId: userId,
      name: _businessNameController.text.trim(),
      preferredLanguage: _preferredLanguage,
      whatsappNumber: '+91${_whatsappController.text.trim()}',
      gstin: _gstinController.text.trim().isNotEmpty ? _gstinController.text.trim() : null,
      defaultShippingCostMinor: (shippingRupees * 100).round(),
      defaultPackagingCostMinor: (packagingRupees * 100).round(),
      defaultReturnRate: _expectedReturnRate,
      defaultRtoRate: _expectedRtoRate,
    );

    ref.read(currentBusinessProvider.notifier).state = business;
    ref.read(authNotifierProvider.notifier).markOnboardingComplete();

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Seller Business'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Welcome to Qwenton CommerceOps',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set up your store details and cost parameters. We use these to calculate true net profit on every order.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // 1. Business Profile Card
                _buildSectionHeader('1. Business Profile'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store / Brand Name *',
                    hintText: 'e.g. Chikankari Studio Jaipur',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Store name is required' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp Business Number *',
                    hintText: '98765 43210',
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                  validator: (val) => val == null || val.trim().length != 10 ? 'Enter valid 10-digit WhatsApp number' : null,
                ),
                const SizedBox(height: 14),

                // Language Choice
                const Text('Preferred Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('English (EN)'),
                        selected: _preferredLanguage == 'en',
                        onSelected: (val) => setState(() => _preferredLanguage = 'en'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('हिंदी (Hindi)'),
                        selected: _preferredLanguage == 'hi',
                        onSelected: (val) => setState(() => _preferredLanguage = 'hi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _gstinController,
                  decoration: const InputDecoration(
                    labelText: 'GSTIN (Optional)',
                    hintText: 'e.g. 08AAAAA0000A1Z5',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Default Cost Assumptions Card
                _buildSectionHeader('2. Default Cost Benchmarks'),
                const SizedBox(height: 6),
                Text(
                  'These numbers pre-populate new product listings so you never underestimate courier, packaging, or return costs.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _shippingCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Default Shipping (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _packagingCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Packaging Cost (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Expected Return Rate Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expected Customer Return Rate:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${_expectedReturnRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      Slider(
                        value: _expectedReturnRate,
                        min: 0,
                        max: 25,
                        divisions: 25,
                        label: '${_expectedReturnRate.round()}%',
                        onChanged: (val) => setState(() => _expectedReturnRate = val),
                      ),
                      const SizedBox(height: 6),

                      // Expected RTO Rate Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expected COD RTO (Doorstep Rejection):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${_expectedRtoRate.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      Slider(
                        value: _expectedRtoRate,
                        min: 0,
                        max: 40,
                        divisions: 40,
                        activeColor: Colors.red.shade400,
                        label: '${_expectedRtoRate.round()}%',
                        onChanged: (val) => setState(() => _expectedRtoRate = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Complete Onboarding & Enter App'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }
}
