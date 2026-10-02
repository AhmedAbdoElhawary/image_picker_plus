import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// a centered card on wide windows, the full page on narrow ones.
class EditFrame extends StatefulWidget {
  final Widget child;

  const EditFrame({required this.child, super.key});

  @override
  State<EditFrame> createState() => _EditFrameState();
}

class _EditFrameState extends State<EditFrame> {
  // the page keeps its crop, filters and order when a resize crosses the breakpoint
  final GlobalKey _page = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final page = KeyedSubtree(key: _page, child: widget.child);
        if (constraints.maxWidth < PickerLayout.cardBreakpoint) return page;
        const radius = BorderRadius.all(Radius.circular(PickerLayout.radius));
        return Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(PickerLayout.cardMargin),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PickerLayout.cardMaxWidth,
                maxHeight: PickerLayout.cardMaxHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [BoxShadow(color: theme.barrier, blurRadius: 40, offset: const Offset(0, 12))],
                ),
                child: ClipRRect(borderRadius: radius, child: page),
              ),
            ),
          ),
        );
      },
    );
  }
}
