import 'package:flutter/material.dart';

import 'base_custom_state.dart';

class CustomStateBuilder<T extends BaseCustomState> extends StatefulWidget {
  final T state;
  final bool Function(T, T) buildWhen;
  final Widget Function(BuildContext, T) builder;

  const CustomStateBuilder({
    required this.state,
    required this.buildWhen,
    required this.builder,
    super.key,
  });

  @override
  State<CustomStateBuilder> createState() => _CustomStateBuilderState<T>();
}

class _CustomStateBuilderState<T extends BaseCustomState> extends State<CustomStateBuilder> {
  late BaseCustomState _currentState;
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
    if (widget.buildWhen(_currentState, widget.state)) {
      setState(() => _currentState = widget.state);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.state);
  }
}
