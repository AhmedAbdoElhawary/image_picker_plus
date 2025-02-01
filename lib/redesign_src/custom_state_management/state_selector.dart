import 'package:flutter/material.dart';

import 'base_custom_state.dart';

class CustomStateSelector<T extends BaseCustomState> extends StatefulWidget {
  final T state;
  final List<String> keys;
  final Widget Function(BuildContext context) builder;

  const CustomStateSelector({
    required this.keys,
    required this.state,
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
    widget.state.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final changedKeys = widget.state.changedKeys;
    if (changedKeys.intersection(widget.keys.toSet()).isNotEmpty) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
