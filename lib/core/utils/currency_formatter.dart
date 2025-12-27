import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    // Format with comma separator first (en_US logic), then replace with space
    // This ensures "1 030 000" format regardless of locale settings affecting NumberFormat
    return NumberFormat("#,###", "en_US").format(amount).replaceAll(',', ' ');
  }
}
