import 'package:flutter/material.dart';

class ParentContext {
  static final ParentContext _instance = ParentContext._internal();
  factory ParentContext() => _instance;
  ParentContext._internal();

  BuildContext? _parentContext;

  BuildContext? get getContext => _parentContext;

  void initializeContext(BuildContext context) {
    _parentContext = context;
  }
}
