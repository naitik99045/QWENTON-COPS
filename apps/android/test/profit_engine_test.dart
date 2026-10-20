import 'package:test/test.dart';
import '../lib/core/utils/paise_currency.dart';
import '../lib/core/profit_engine/profit_calculator.dart';

void main() {
  group('Paise Currency Unit Tests', () {
    test('Converts rupees to paise and formats correctly', () {
      final p1 = Paise.fromRupees(999.50);
      expect(p1.value, equals(99950));
      expect(p1.toFormattedRupees(), equals('₹999.50'));
      expect(p1.toFormattedRupees(showDecimals: false), equals('₹999'));

      final p2 = Paise.fromWholeRupees(1500);
      expect(p2.value, equals(150000));
      expect(p2.toFormattedRupees(), equals('₹1,500.00'));
    });

    test('Formats Indian number groupings (Lakhs)', () {
      final pLakh = Paise(10000000); // 1,00,000 Rupees
      expect(pLakh.toFormattedRupees(showDecimals: false), equals('₹1,00,000'));

      final pTenLakh = Paise(100000000); // 10,00,000 Rupees
      expect(pTenLakh.toFormattedRupees(showDecimals: false), equals('₹10,00,000'));
    });

    test('Handles negative amounts cleanly for RTO losses', () {
      final loss = Paise(-11500); // -₹115.00
      expect(loss.toFormattedRupees(), equals('-₹115.00'));
      expect(loss.toFormattedRupees(showDecimals: false), equals('-₹115'));
    });

    test('Arithmetic operations preserve integer precision', () {
      final a = const Paise(10050); // ₹100.50
      final b = const Paise(4950);  // ₹49.50
      final sum = a + b;
      expect(sum.value, equals(15000));
      expect(sum.toFormattedRupees(), equals('₹150.00'));

      final diff = a - b;
      expect(diff.value, equals(5100));
      expect(diff.toFormattedRupees(), equals('₹51.00'));
    });
  });

  group('Profit Engine Estimated Profit Calculation Tests', () {
    test('Standard Pink Kurti pricing matches PRD specification', () {
      // Selling: ₹999 (99900 paise)
      // Discount: ₹50 (5000 paise) -> Net Sales: ₹949 (94900 paise)
      // COGS: ₹320 (32000 paise)
      // Packaging: ₹25 (2500 paise)
      // Shipping: ₹70 (7000 paise)
      // Gateway Fee: 2% -> ₹18.98 (1898 paise)
      // Expected Return: 5% * 50% handling = 2.5% of ₹949 -> ₹23.72 (2372 paise)
      // Expected RTO: 10% * 2x shipping (₹140) = ₹14.00 (1400 paise)
      final result = ProfitEngine.calculateEstimatedProfit(
        sellingPriceMinor: 99900,
        discountMinor: 5000,
        productCostMinor: 32000,
        packagingCostMinor: 2500,
        shippingCostMinor: 7000,
        paymentFeeRate: 0.0200,
        expectedReturnRate: 5.0,
        expectedRtoRate: 10.0,
      );

      expect(result.netSales.value, equals(94900));
      expect(result.paymentFee.value, equals(1898));
      expect(result.expectedReturnCost.value, anyOf(equals(2372), equals(2373)));
      expect(result.expectedRtoCost.value, equals(1400));

      // 94900 - 32000 - 2500 - 7000 - 1898 - (2372/2373) - 1400 = 47730/47729 paise (~₹477.30)
      expect(result.estimatedProfit.value, anyOf(equals(47730), equals(47729)));
      expect(result.isProfitable, isTrue);
      expect(result.contributionMarginPercent, greaterThan(50.0));
    });

    test('COD order with 0% gateway fee', () {
      final result = ProfitEngine.calculateEstimatedProfit(
        sellingPriceMinor: 149900,
        discountMinor: 0,
        productCostMinor: 52000,
        packagingCostMinor: 3000,
        shippingCostMinor: 8000,
        paymentFeeRate: 0.0, // Zero PG fee for direct COD
        expectedReturnRate: 6.0,
        expectedRtoRate: 12.0,
      );

      expect(result.paymentFee.value, equals(0));
      expect(result.netSales.value, equals(149900));
      expect(result.isProfitable, isTrue);
    });

    test('Selling at a heavy discount detects unprofitable sale', () {
      final result = ProfitEngine.calculateEstimatedProfit(
        sellingPriceMinor: 50000, // ₹500
        discountMinor: 35000,     // ₹350 discount -> Net sales ₹150 (15000 paise)
        productCostMinor: 25000,  // COGS ₹250 (already > net sales)
        packagingCostMinor: 2000, // ₹20
        shippingCostMinor: 6000,  // ₹60
      );

      expect(result.isProfitable, isFalse);
      expect(result.estimatedProfit.value, lessThan(0));
      expect(result.contributionMarginPercent, lessThan(0.0));
    });
  });

  group('Profit Engine Realised Profit Calculation Tests', () {
    test('Delivered state yields full realised profit', () {
      final result = ProfitEngine.calculateRealisedProfit(
        fulfilmentStatus: 'delivered',
        subtotalMinor: 99900,
        discountMinor: 5000,
        actualProductCostMinor: 32000,
        actualPackagingCostMinor: 2500,
        actualShippingMinor: 7000,
        actualPaymentFeeMinor: 1898,
      );

      // Net Sales (94900) - Total Cost (43398) = 51502 paise (₹515.02)
      expect(result.actualSettlement.value, equals(94900));
      expect(result.realisedProfit.value, equals(51502));
      expect(result.realisedMarginPercent, greaterThan(54.0));
    });

    test('RTO state yields negative profit (packaging + 2x courier shipping loss)', () {
      final result = ProfitEngine.calculateRealisedProfit(
        fulfilmentStatus: 'rto',
        subtotalMinor: 34900,
        discountMinor: 0,
        actualProductCostMinor: 8000,
        actualPackagingCostMinor: 1500, // ₹15 packaging
        actualShippingMinor: 5000,     // ₹50 forward shipping
        actualPaymentFeeMinor: 0,
      );

      // Loss: Packaging (₹15) + Forward (₹50) + Return (₹50) = ₹115 loss (-11500 paise)
      expect(result.actualSettlement.value, equals(0));
      expect(result.realisedProfit.value, equals(-11500));
      expect(result.realisedProfit.toFormattedRupees(), equals('-₹115.00'));
    });

    test('Customer Return state calculates reverse courier loss', () {
      final result = ProfitEngine.calculateRealisedProfit(
        fulfilmentStatus: 'returned',
        subtotalMinor: 149900,
        discountMinor: 0,
        actualProductCostMinor: 52000,
        actualPackagingCostMinor: 3000, // ₹30
        actualShippingMinor: 8000,     // ₹80 forward
        actualPaymentFeeMinor: 2998,   // ~₹30 gateway fee
        actualReverseCourierMinor: 6000, // ₹60 reverse courier
      );

      // Loss: Packaging (3000) + Forward (8000) + Reverse (6000) + PG fee (2998) = 19998 paise (-₹199.98)
      expect(result.actualSettlement.value, equals(0));
      expect(result.realisedProfit.value, equals(-19998));
    });

    test('Cancelled before dispatch incurs zero financial loss', () {
      final result = ProfitEngine.calculateRealisedProfit(
        fulfilmentStatus: 'cancelled',
        subtotalMinor: 99900,
        discountMinor: 0,
        actualProductCostMinor: 32000,
        actualPackagingCostMinor: 2500,
        actualShippingMinor: 7000,
        actualPaymentFeeMinor: 0,
      );

      expect(result.realisedProfit.value, equals(0));
      expect(result.actualSettlement.value, equals(0));
    });
  });
}
