import 'package:flutter/material.dart';

import 'base_custom_state.dart';

class CustomStateSelector<T extends BaseCustomState> extends StatefulWidget {
  final T controller;
  final List<String> keys;
  final Widget Function(BuildContext context) builder;

  const CustomStateSelector({
    this.keys = const [],
    required this.controller,
    required this.builder,
    super.key,
  });

  @override
  State<CustomStateSelector> createState() => _CustomStateSelectorState();
}

class _CustomStateSelectorState extends State<CustomStateSelector> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final changedKeys = widget.controller.changedKeys;
    if (changedKeys.intersection(widget.keys.toSet()).isNotEmpty) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
