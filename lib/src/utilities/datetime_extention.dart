import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {

  String get toMMMdy {
    return DateFormat('MMM d, y').format(this);
  }

  String get toYyyyMMdd {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}
