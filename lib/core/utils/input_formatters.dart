import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats input as currency: 1000 -> 1 000
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove non-digits
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Parse to int
    int value = int.tryParse(newText) ?? 0;

    // Use NumberFormat but force space separator
    final formatter = NumberFormat.decimalPattern('ru');
    // Format and replace potential NBSP (\u00A0) with standard space (0x20)
    String formatted = formatter.format(value).replaceAll('\u00A0', ' ');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats input as KZ phone: +7 (XXX) XXX-XX-XX
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Get only digits
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 2. Limit length (11 digits max for +7...)
    if (digits.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    // Default prefix if empty or starting fresh
    if (digits.isEmpty) {
      return newValue;
    }

    // Always start with +7
    buffer.write('+7');

    // Process remaining digits (skip first '7' or '8' if present essentially)
    int index = 0;
    // Check if user started typing 8 or 7, ignore it for the body
    if (digits.isNotEmpty && (digits[0] == '7' || digits[0] == '8')) {
      index = 1;
    }

    if (index < digits.length) {
      buffer.write(' (');
      // Area code (3 chars)
      for (int i = 0; i < 3; i++) {
        if (index >= digits.length) break;
        buffer.write(digits[index++]);
      }
      if (index < digits.length ||
          digits.length > (digits[0] == '7' || digits[0] == '8' ? 4 : 3)) {
        buffer.write(') ');
      }
    }

    // First 3 part of number
    if (index < digits.length) {
      for (int i = 0; i < 3; i++) {
        if (index >= digits.length) break;
        buffer.write(digits[index++]);
      }
      if (index < digits.length) buffer.write('-');
    }

    // Second 2 part
    if (index < digits.length) {
      for (int i = 0; i < 2; i++) {
        if (index >= digits.length) break;
        buffer.write(digits[index++]);
      }
      if (index < digits.length) buffer.write('-');
    }

    // Last 2 part
    if (index < digits.length) {
      for (int i = 0; i < 2; i++) {
        if (index >= digits.length) break;
        buffer.write(digits[index++]);
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
