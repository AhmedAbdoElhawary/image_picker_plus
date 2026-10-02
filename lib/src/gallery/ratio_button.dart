import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/durations.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/core/selector.dart';
import 'package:image_picker_plus/src/edit/crop_controller.dart';
import 'package:image_picker_plus/src/settings/crop_ratio.dart';

/// opens a menu under it with the crop ratios the developer allows.
class RatioButton extends StatefulWidget {
  final CropController controller;

  const RatioButton({required this.controller, super.key});

  @override
  State<RatioButton> createState() => _RatioButtonState();
}

class _RatioButtonState extends State<RatioButton> with SingleTickerProviderStateMixin {
  final OverlayPortalController _menu = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final Object _tapGroup = Object();
  late final AnimationController _open = AnimationController(vsync: this);

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _toggle() => _menu.isShowing && _open.status != AnimationStatus.reverse ? _close() : _show();

  void _show() {
    _menu.show();
    _open.duration = PickerDurations.of(context).short;
    _open.forward();
  }

  Future<void> _close() async {
    // a reopen during the close stops it, and then this never gets past the await
    await _open.reverse();
    if (mounted) _menu.hide();
  }

  void _pick(CropRatio ratio) {
    widget.controller.ratio = ratio;
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final controller = widget.controller;
    return TapRegion(
      groupId: _tapGroup,
      onTapOutside: (_) {
        if (_menu.isShowing) _close();
      },
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _menu,
          overlayChildBuilder: (overlayContext) => _RatioMenu(
            controller: controller,
            animation: _open,
            link: _link,
            tapGroup: _tapGroup,
            above: _opensAbove(overlayContext, scope.settings.cropRatios.length),
            onPick: _pick,
          ),
          child: Selector<CropRatio>(
            listenable: controller,
            select: () => controller.ratio,
            builder: (context, ratio) => Semantics(
              button: true,
              label: scope.texts.crop,
              child: Material(
                color: scope.theme.surface,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _toggle,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: PickerLayout.minTouch * 0.8,
                      minWidth: PickerLayout.minTouch,
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.crop_rounded, size: 18, color: scope.theme.onSurface),
                          const SizedBox(width: 6),
                          Text(
                            _RatioMenu.label(ratio, scope),
                            style: TextStyle(color: scope.theme.onSurface, fontWeight: FontWeight.w600),
                          ),
                          RotationTransition(
                            turns: Tween<double>(begin: 0, end: 0.5).animate(_open),
                            child: Icon(Icons.expand_more_rounded, size: 20, color: scope.theme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// the button can sit low, like on the edit page, where a menu under it would go off screen.
  bool _opensAbove(BuildContext overlayContext, int count) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final menuHeight = count * PickerLayout.minTouch + _RatioMenu.gap + _RatioMenu.padding * 2;
    return bottom + menuHeight >
        MediaQuery.sizeOf(overlayContext).height - MediaQuery.paddingOf(overlayContext).bottom;
  }
}

class _RatioMenu extends StatelessWidget {
  final CropController controller;
  final Animation<double> animation;
  final LayerLink link;
  final Object tapGroup;
  final bool above;
  final ValueChanged<CropRatio> onPick;

  const _RatioMenu({
    required this.controller,
    required this.animation,
    required this.link,
    required this.tapGroup,
    required this.above,
    required this.onPick,
  });

  static const double gap = 8;
  static const double padding = 6;

  static String label(CropRatio ratio, PickerScope scope) =>
      ratio == CropRatio.original ? scope.texts.original : "$ratio";

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;
    final start = Directionality.of(context) == TextDirection.ltr ? -1.0 : 1.0;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: Alignment(start, above ? -1 : 1),
        followerAnchor: Alignment(start, above ? 1 : -1),
        offset: Offset(0, above ? -gap : gap),
        child: TapRegion(
          groupId: tapGroup,
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
              alignment: Alignment(start, above ? 1 : -1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(PickerLayout.radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Material(
                    color: theme.surface,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(vertical: padding),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 148),
                        child: IntrinsicWidth(
                          child: Selector<CropRatio>(
                            listenable: controller,
                            select: () => controller.ratio,
                            builder: (context, current) => Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final ratio in scope.settings.cropRatios)
                                  _RatioRow(
                                    ratio: ratio,
                                    selected: ratio == current,
                                    onTap: () => onPick(ratio),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  final CropRatio ratio;
  final bool selected;
  final VoidCallback onTap;

  const _RatioRow({required this.ratio, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final theme = scope.theme;
    final color = selected ? theme.onSurface : theme.onSurface.withValues(alpha: 0.6);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: PickerLayout.minTouch * 0.8,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
            child: Row(
              children: [
                _RatioShape(ratio: ratio, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _RatioMenu.label(ratio, scope),
                    style: TextStyle(color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: PickerDurations.of(context).short,
                  child: Icon(Icons.check_rounded, size: 18, color: theme.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// a small outline with the ratio's shape, original has none so it gets the photo icon.
class _RatioShape extends StatelessWidget {
  final CropRatio ratio;
  final Color color;

  const _RatioShape({required this.ratio, required this.color});

  static const double _size = 18;

  @override
  Widget build(BuildContext context) {
    final value = ratio.ratio;
    if (value == null) return Icon(Icons.photo_outlined, size: _size, color: color);
    return SizedBox.square(
      dimension: _size,
      child: Center(
        child: SizedBox(
          width: value >= 1 ? _size : _size * value,
          height: value >= 1 ? _size / value : _size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
