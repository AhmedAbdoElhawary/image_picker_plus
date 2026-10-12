import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show HapticFeedback;

void customHapticFeedback() {
  defaultTargetPlatform == TargetPlatform.iOS ? HapticFeedback.heavyImpact() : HapticFeedback.vibrate();
}
