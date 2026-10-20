/// Value-object and utility for financial math using integer minor units (Paise).
/// 1 Rupee = 100 Paise.
class Paise {
  final int value;

  const Paise(this.value);

  /// Create Paise from a Rupee decimal amount (e.g. 999.50 -> 99950 Paise)
  factory Paise.fromRupees(double rupees) {
    return Paise((rupees * 100).round());
  }

  /// Create Paise from whole Rupees (e.g. 999 -> 99900 Paise)
  factory Paise.fromWholeRupees(int rupees) {
    return Paise(rupees * 100);
  }

  /// Converts Paise to Rupee double value (for display or chart calculations only)
  double toRupees() => value / 100.0;

  /// Formatted string in Indian currency notation: e.g. "₹999.00" or "₹14,999.50"
  String toFormattedRupees({bool showDecimals = true, String symbol = '₹'}) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final whole = absVal ~/ 100;
    final fraction = absVal % 100;

    final formattedWhole = _formatIndianGrouping(whole);

    final sign = isNegative ? '-' : '';
    if (showDecimals) {
      final paddedFraction = fraction.toString().padLeft(2, '0');
      return '$sign$symbol$formattedWhole.$paddedFraction';
    } else {
      return '$sign$symbol$formattedWhole';
    }
  }

  /// Formats integers according to the Indian numbering system (Lakhs, Crores)
  /// e.g. 100000 -> "1,00,000"
  static String _formatIndianGrouping(int number) {
    final str = number.toString();
    if (str.length <= 3) return str;

    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);
    return buffer.toString();
  }

  Paise operator +(Paise other) => Paise(value + other.value);
  Paise operator -(Paise other) => Paise(value - other.value);
  Paise operator *(num factor) => Paise((value * factor).round());

  bool operator <(Paise other) => value < other.value;
  bool operator <=(Paise other) => value <= other.value;
  bool operator >(Paise other) => value > other.value;
  bool operator >=(Paise other) => value >= other.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Paise && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => toFormattedRupees();
}
