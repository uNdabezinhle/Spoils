import 'package:intl/intl.dart';

final zarFormatter = NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0);

String formatZar(dynamic amount) {
  final value = amount is String ? double.tryParse(amount) ?? 0 : (amount as num).toDouble();
  return zarFormatter.format(value);
}