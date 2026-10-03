import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Prices are integer cents everywhere; only display converts to a currency string.
String formatMoney(int cents, {String currency = AppConfig.currency}) =>
    NumberFormat.simpleCurrency(name: currency).format(cents / 100);

String formatDate(DateTime date) => DateFormat.yMMMd().format(date.toLocal());
