import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final formatter = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
  return formatter.format(value);
}

String formatCurrencyNoSymbol(double value) {
  final formatter = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);
  return formatter.format(value).trim();
}
