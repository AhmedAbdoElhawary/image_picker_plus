import 'package:flutter/widgets.dart';

class PickerDurations {
  final Duration short;
  final Duration medium;
  final Duration long;

  const PickerDurations._(this.short, this.medium, this.long);

  static const PickerDurations _normal = PickerDurations._(
    Duration(milliseconds: 150),
    Duration(milliseconds: 250),
    Duration(milliseconds: 350),
  );
  static const PickerDurations _none = PickerDurations._(Duration.zero, Duration.zero, Duration.zero);

  factory PickerDurations.of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? _none : _normal;
}
