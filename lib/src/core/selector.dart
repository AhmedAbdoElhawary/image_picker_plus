import 'package:flutter/widgets.dart';

/// rebuilds only when [select] gives a different value, not on every notify.
class Selector<R> extends StatefulWidget {
  final Listenable listenable;
  final R Function() select;
  final Widget Function(BuildContext context, R value, Widget? child) builder;

  /// built once and given to [builder], for the part that doesn't depend on the value.
  final Widget? child;

  const Selector({
    required this.listenable,
    required this.select,
    required this.builder,
    this.child,
    super.key,
  });

  @override
  State<Selector<R>> createState() => _SelectorState<R>();
}

class _SelectorState<R> extends State<Selector<R>> {
  late R _value;

  @override
  void initState() {
    super.initState();
    _value = widget.select();
    widget.listenable.addListener(_onChange);
  }

  @override
  void didUpdateWidget(Selector<R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onChange);
      widget.listenable.addListener(_onChange);
    }
    _value = widget.select();
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final value = widget.select();
    if (value == _value) return;
    setState(() => _value = value);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value, widget.child);
}
