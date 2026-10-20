import '../utils/paise_currency.dart';

/// Structured result of the Estimated Profit calculation
class EstimatedProfitResult {
  final Paise netSales;
  final Paise paymentFee;
  final Paise productCost;
  final Paise packagingCost;
  final Paise shippingCost;
  final Paise expectedReturnCost;
  final Paise expectedRtoCost;
  final Paise estimatedProfit;
  final double contributionMarginPercent;
  final bool isProfitable;

  const EstimatedProfitResult({
    required this.netSales,
    required this.paymentFee,
    required this.productCost,
    required this.packagingCost,
    required this.shippingCost,
    required this.expectedReturnCost,
    required this.expectedRtoCost,
    required this.estimatedProfit,
    required this.contributionMarginPercent,
    required this.isProfitable,
  });

  Map<String, dynamic> toMap() {
    return {
      'net_sales_minor': netSales.value,
      'payment_fee_minor': paymentFee.value,
      'product_cost_minor': productCost.value,
      'packaging_cost_minor': packagingCost.value,
      'shipping_cost_minor': shippingCost.value,
      'expected_return_cost_minor': expectedReturnCost.value,
      'expected_rto_cost_minor': expectedRtoCost.value,
      'estimated_profit_minor': estimatedProfit.value,
      'contribution_margin_pct': contributionMarginPercent,
      'is_profitable': isProfitable,
    };
  }
}

/// Structured result of the Realised Profit calculation
class RealisedProfitResult {
  final Paise actualSettlement;
  final Paise totalCostsIncurred;
  final Paise realisedProfit;
  final double realisedMarginPercent;
  final String statusSummary;

  const RealisedProfitResult({
    required this.actualSettlement,
    required this.totalCostsIncurred,
    required this.realisedProfit,
    required this.realisedMarginPercent,
    required this.statusSummary,
  });
}

/// The core mathematical calculation engine of Qwenton CommerceOps.
/// All monetary values must be supplied in minor units (Paise).
class ProfitEngine {
  /// Default ratio of net sales lost on reverse handling if item is returned (50%)
  static const double defaultReturnHandlingRatio = 0.50;

  /// Calculates Estimated Profit for an order or prospective product pricing.
  static EstimatedProfitResult calculateEstimatedProfit({
    required int sellingPriceMinor,
    int discountMinor = 0,
    required int productCostMinor,
    int packagingCostMinor = 0,
    int shippingCostMinor = 0,
    double paymentFeeRate = 0.0200, // 2% gateway fee by default
    double expectedReturnRate = 5.0, // 5% expected return rate
    double expectedRtoRate = 10.0, // 10% expected RTO rate
    double returnHandlingCostRatio = defaultReturnHandlingRatio,
  }) {
    final netSalesVal = sellingPriceMinor - discountMinor;
    final netSales = Paise(netSalesVal > 0 ? netSalesVal : 0);

    // 1. Payment Gateway Fee
    final paymentFee = Paise((netSales.value * paymentFeeRate).round());

    // 2. Expected Return Cost: Probability-weighted reverse handling loss
    final expectedReturnCost = Paise(
      (netSales.value * (expectedReturnRate / 100.0) * returnHandlingCostRatio).round(),
    );

    // 3. Expected RTO Cost: Probability-weighted forward + reverse courier loss
    // RTO typically incurs 2x courier shipping charge
    final expectedRtoCost = Paise(
      ((shippingCostMinor * 2) * (expectedRtoRate / 100.0)).round(),
    );

    // 4. Net Estimated Contribution Profit
    final estimatedProfitVal = netSales.value
        - productCostMinor
        - packagingCostMinor
        - shippingCostMinor
        - paymentFee.value
        - expectedReturnCost.value
        - expectedRtoCost.value;

    final estimatedProfit = Paise(estimatedProfitVal);

    // 5. Margin Percentage
    final marginPercent = netSales.value > 0
        ? (estimatedProfitVal / netSales.value) * 100.0
        : 0.0;

    return EstimatedProfitResult(
      netSales: netSales,
      paymentFee: paymentFee,
      productCost: Paise(productCostMinor),
      packagingCost: Paise(packagingCostMinor),
      shippingCost: Paise(shippingCostMinor),
      expectedReturnCost: expectedReturnCost,
      expectedRtoCost: expectedRtoCost,
      estimatedProfit: estimatedProfit,
      contributionMarginPercent: double.parse(marginPercent.toStringAsFixed(2)),
      isProfitable: estimatedProfitVal > 0,
    );
  }

  /// Calculates Realised Profit when an order reaches terminal status.
  static RealisedProfitResult calculateRealisedProfit({
    required String fulfilmentStatus,
    required int subtotalMinor,
    int discountMinor = 0,
    required int actualProductCostMinor,
    required int actualPackagingCostMinor,
    required int actualShippingMinor,
    required int actualPaymentFeeMinor,
    int actualReverseCourierMinor = 0,
    int actualDamageMinor = 0,
  }) {
    final netSales = subtotalMinor - discountMinor;

    switch (fulfilmentStatus.toLowerCase()) {
      case 'delivered':
        // Full revenue collected; normal order costs deducted
        final totalCost = actualProductCostMinor +
            actualPackagingCostMinor +
            actualShippingMinor +
            actualPaymentFeeMinor;
        final profit = netSales - totalCost;
        final margin = netSales > 0 ? (profit / netSales) * 100.0 : 0.0;
        return RealisedProfitResult(
          actualSettlement: Paise(netSales),
          totalCostsIncurred: Paise(totalCost),
          realisedProfit: Paise(profit),
          realisedMarginPercent: double.parse(margin.toStringAsFixed(2)),
          statusSummary: 'Delivered - Full profit realised',
        );

      case 'rto':
        // Buyer rejected/cancelled at doorstep.
        // Product is returned to inventory (product cost not lost unless damaged).
        // Seller loses: Packaging + Forward Shipping + Reverse Shipping + Damaged goods.
        final totalLoss = actualPackagingCostMinor +
            (actualShippingMinor * 2) +
            actualDamageMinor;
        return RealisedProfitResult(
          actualSettlement: const Paise(0),
          totalCostsIncurred: Paise(totalLoss),
          realisedProfit: Paise(-totalLoss),
          realisedMarginPercent: -100.0,
          statusSummary: 'RTO - Courier & packaging loss incurred',
        );

      case 'returned':
        // Buyer accepted delivery, then returned item.
        // Full refund issued to buyer. Product returned to stock.
        // Seller loses: Packaging + Forward Shipping + Reverse Courier Fee.
        final reverseFee = actualReverseCourierMinor > 0
            ? actualReverseCourierMinor
            : (actualShippingMinor * 0.8).round();
        final totalLoss = actualPackagingCostMinor +
            actualShippingMinor +
            reverseFee +
            actualPaymentFeeMinor;
        return RealisedProfitResult(
          actualSettlement: const Paise(0),
          totalCostsIncurred: Paise(totalLoss),
          realisedProfit: Paise(-totalLoss),
          realisedMarginPercent: -100.0,
          statusSummary: 'Customer Return - Reverse logistics fee incurred',
        );

      case 'cancelled':
      default:
        return const RealisedProfitResult(
          actualSettlement: Paise(0),
          totalCostsIncurred: Paise(0),
          realisedProfit: Paise(0),
          realisedMarginPercent: 0.0,
          statusSummary: 'Cancelled before dispatch - Zero loss',
        );
    }
  }
}
