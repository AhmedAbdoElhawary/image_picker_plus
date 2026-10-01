import 'package:flutter/material.dart';

abstract class BaseCustomState extends ChangeNotifier {
  final Set<String> _changedKeys = {};
  Set<String> get changedKeys => _changedKeys;

  /// helper method to update state and track keys
  void updateState(List<String> keys) {
    _changedKeys.addAll(keys);
    notifyListeners();

    // Reset after notify
    _changedKeys.clear();
  }
}
