import 'package:flutter/widgets.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';

/// dims outside [window] and draws thirds lines inside it.
class CropOverlay extends StatelessWidget {
  final Rect window;
  final bool showGrid;

  const CropOverlay({required this.window, this.showGrid = false, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = PickerScope.of(context).theme;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _OverlayPainter(window: window, showGrid: showGrid, scrim: theme.scrim, line: theme.onAccent),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect window;
  final bool showGrid;
  final Color scrim;
  final Color line;

  _OverlayPainter({required this.window, required this.showGrid, required this.scrim, required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(window),
    );
    canvas.drawPath(outside, Paint()..color = scrim);
    final border = Paint()
      ..color = line.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(window, border);
    if (!showGrid) return;
    final grid = Paint()
      ..color = line.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 3; i++) {
      final x = window.left + window.width * i / 3;
      final y = window.top + window.height * i / 3;
      canvas.drawLine(Offset(x, window.top), Offset(x, window.bottom), grid);
      canvas.drawLine(Offset(window.left, y), Offset(window.right, y), grid);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.window != window || old.showGrid != showGrid || old.scrim != scrim || old.line != line;
}
