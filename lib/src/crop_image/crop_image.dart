import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const _kCropGridColumnCount = 3;
const _kCropGridRowCount = 3;
const _kCropHandleSize = 0.0;
const _kCropHandleHitSize = 48.0;

enum _CropAction { none, moving, cropping, scaling }

enum _CropHandleSide { none, topLeft, topRight, bottomLeft, bottomRight }

enum CropEditImageType { normal, circle, banner }

class CustomCropper extends StatefulWidget {
  final File image;
  final double aspectRatio;
  final double maximumScale;

  final bool alwaysShowGrid;
  final bool enableInteract;
  final Color paintColor;
  final Color gridColor;
  final Color overlayColor;
  final ImageErrorListener? onImageError;
  final ValueChanged<bool>? scrollCustomList;
  final List<double> colorMatrix;
  final void Function(bool value) isCroppingReady;
  final Size initialBoundaries;
  final CropEditImageType type;
  final int rotateAngle;

  const CustomCropper({
    super.key,
    required this.paintColor,
    required this.rotateAngle,
    required this.gridColor,
    required this.overlayColor,
    required this.aspectRatio,
    this.type = CropEditImageType.normal,
    this.scrollCustomList,
    this.maximumScale = 2.0,
    this.alwaysShowGrid = false,
    this.enableInteract = true,
    this.onImageError,
    required this.initialBoundaries,
    required this.colorMatrix,
    required this.image,
    required this.isCroppingReady,
  });

  @override
  State<StatefulWidget> createState() => CustomCropperState();

  static CustomCropperState? of(BuildContext context) =>
      context.findAncestorStateOfType<CustomCropperState>();
}

class CustomCropperState extends State<CustomCropper> with TickerProviderStateMixin {
  final _globalKey = GlobalKey();
  late final AnimationController _activeController;
  late final AnimationController _settleController;

  double _scale = 1.0;
  double _ratio = 1.0;
  Rect _view = Rect.zero;
  Rect _area = Rect.zero;
  Size initialBoundaries = Size.zero;
  Offset _lastFocalPoint = Offset.zero;
  _CropAction _action = _CropAction.none;
  _CropHandleSide _handle = _CropHandleSide.none;

  late double _startScale;
  late Rect _startView;
  late Tween<Rect?> _viewTween;
  late Tween<double> _scaleTween;

  ImageStream? _imageStream;
  ui.Image? _image;
  ImageStreamListener? _imageListener;

  int _rotationAngle = 0;

  set setRotateAngle(int angle) {
    if (angle == _rotationAngle) return;
    _rotationAngle = angle;

    setState(() {});
  }

  double get scale => _area.shortestSide / _scale;
  ui.Image? get image => _image;
  double get getWidth => initialBoundaries.width;
  double get getAspectRatio => widget.aspectRatio;

  Rect? get area => _view.isEmpty
      ? null
      : Rect.fromLTWH(
          _area.left * _view.width / _scale - _view.left,
          _area.top * _view.height / _scale - _view.top,
          _area.width * _view.width / _scale,
          _area.height * _view.height / _scale,
        );
  bool get _isEnabled => (_view.isEmpty == false && _image != null) && widget.enableInteract;

  final Map<double, double> _maxAreaWidthMap = {};

  int pointers = 0;

  @override
  void initState() {
    super.initState();
    initialBoundaries = widget.initialBoundaries;
    setRotateAngle = widget.rotateAngle;
    _activeController = AnimationController(
      vsync: this,
      value: widget.alwaysShowGrid ? 1.0 : 0.0,
    )..addListener(() => setState(() {}));
    _settleController = AnimationController(vsync: this)..addListener(_settleAnimationChanged);
  }

  @override
  void dispose() {
    final listener = _imageListener;
    if (listener != null) {
      _imageStream?.removeListener(listener);
    }
    _activeController.dispose();
    _settleController.dispose();

    super.dispose();
  }

  @override
  void setState(fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) super.setState(fn);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getImage();
  }

  @override
  void didUpdateWidget(CustomCropper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialBoundaries != initialBoundaries) {
      initialBoundaries = widget.initialBoundaries;
    }

    if (widget.image != oldWidget.image) {
      _getImage();
    } else if (widget.aspectRatio != oldWidget.aspectRatio) {
      _area = _calculateDefaultArea(
        viewWidth: _view.width,
        viewHeight: _view.height,
        imageWidth: _image?.width,
        imageHeight: _image?.height,
      );
      _handleScaleEnd();
    }
    if (widget.alwaysShowGrid != oldWidget.alwaysShowGrid) {
      if (widget.alwaysShowGrid) {
        _activate();
      } else {
        _deactivate();
      }
    }

    if (widget.rotateAngle != oldWidget.rotateAngle) {
      setRotateAngle = widget.rotateAngle;
    }
  }

  void _getImage({bool force = false}) {
    final oldImageStream = _imageStream;
    FileImage image = FileImage(widget.image, scale: 1.0);
    final newImageStream = image.resolve(createLocalImageConfiguration(context));
    _imageStream = newImageStream;
    if (newImageStream.key != oldImageStream?.key || force) {
      final oldImageListener = _imageListener;
      if (oldImageListener != null) {
        oldImageStream?.removeListener(oldImageListener);
      }
      final newImageListener = ImageStreamListener(_updateImage, onError: widget.onImageError);
      _imageListener = newImageListener;
      newImageStream.addListener(newImageListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foregroundPainter = switch (widget.type) {
      CropEditImageType.banner => _BannerPainter(
          view: _view,
          area: _area,
          active: _activeController.value,
          paintColor: widget.overlayColor,
        ),
      CropEditImageType.circle => _CornerPainter(widget.overlayColor),
      CropEditImageType.normal => null,
    };
    final double rotationAngle = _rotationAngle == 0 ? 0.0 : ((_rotationAngle) * (pi / 180));

    return CustomPaint(
      foregroundPainter: foregroundPainter,
      painter: _GridCropPainter(
        view: _view,
        area: _area,
        active: _activeController.value,
        paintColor: widget.paintColor,
        gridColor: widget.gridColor,
        type: widget.type,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: Listener(
          onPointerDown: widget.enableInteract ? (event) => pointers++ : null,
          onPointerUp: widget.enableInteract ? (event) => pointers = 0 : null,
          child: GestureDetector(
            key: _globalKey,
            behavior: HitTestBehavior.opaque,
            onScaleStart: _isEnabled ? _handleScaleStart : null,
            onScaleUpdate: _isEnabled ? _handleScaleUpdate : null,
            onScaleEnd: _isEnabled ? (d) => _handleScaleEnd() : null,
            child: widget.enableInteract
                ? AnimatedBuilder(
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _CropPainter(
                          image: _image,
                          ratio: _ratio,
                          view: _view,
                          area: _area,
                          scale: _scale,
                          colorFilter: ColorFilter.matrix(widget.colorMatrix),
                          paintColor: widget.paintColor,
                          rotationIndex: rotationAngle,
                        ),
                      );
                    },
                    animation: _activeController,
                  )
                : ColorFiltered(
                    colorFilter: ColorFilter.matrix(widget.colorMatrix),
                    child: Transform.rotate(
                        angle: rotationAngle, child: Image.file(widget.image, fit: BoxFit.cover))),
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _handleScaleStartFun(details.focalPoint);
  }

  void _handleScaleStartFun(Offset focalPoint) {
    _activate();
    _settleController.stop(canceled: false);
    _lastFocalPoint = focalPoint;
    _action = _CropAction.none;
    _handle = _hitCropHandle(_getLocalPoint(focalPoint));
    _startScale = _scale;
    _startView = _view;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    _handleScaleUpdateFun(focalPoint: details.focalPoint, scale: details.scale);
  }

  void _handleScaleUpdateFun({
    required Offset focalPoint,
    required double scale,
  }) {
    if (_action == _CropAction.none) {
      if (_handle == _CropHandleSide.none) {
        _action = pointers == 2 ? _CropAction.scaling : _CropAction.moving;
      } else {
        _action = _CropAction.cropping;
      }
    }
    if (_action == _CropAction.cropping) {
      // Handle cropping as usual (unchanged)
      final boundaries = _boundaries;
      if (boundaries == null) return;
    } else if (_action == _CropAction.moving) {
      // Adjust movement based on rotation
      final delta = focalPoint - _lastFocalPoint;
      _lastFocalPoint = focalPoint;

      Offset adjustedDelta;
      switch (_rotationAngle) {
        case 90:
          adjustedDelta = Offset(delta.dy, -delta.dx);
          break;
        case -90:
          adjustedDelta = Offset(-delta.dy, delta.dx);
          break;

        case 180:
          adjustedDelta = Offset(-delta.dx, -delta.dy);
          break;
        case -180:
          adjustedDelta = Offset(-delta.dx, -delta.dy); // it's true
          break;

        case 270:
          adjustedDelta = Offset(-delta.dy, delta.dx);
          break;
        case -270:
          adjustedDelta = Offset(delta.dy, -delta.dx);
          break;
        default:
          adjustedDelta = delta; // 0 degrees (no adjustment)
      }

      setState(() {
        _view = _view.translate(
          adjustedDelta.dx / (_image!.width * _scale * _ratio),
          adjustedDelta.dy / (_image!.height * _scale * _ratio),
        );
      });
    } else if (_action == _CropAction.scaling) {
      // Handle scaling as usual (unchanged)
      final image = _image;
      final boundaries = _boundaries;
      if (image == null || boundaries == null) return;

      setState(() {
        _scale = _startScale * scale;
        final dx = boundaries.width * (1.0 - scale) / (image.width * _scale * _ratio);
        final dy = boundaries.height * (1.0 - scale) / (image.height * _scale * _ratio);
        _view = Rect.fromLTWH(
          _startView.left + dx / 2,
          _startView.top + dy / 2,
          _startView.width,
          _startView.height,
        );
      });
    }
  }

  void _handleScaleEnd() {
    if (widget.scrollCustomList != null) widget.scrollCustomList!(false);

    _deactivate();
    final minimumScale = _minimumScale;
    if (minimumScale == null) return;

    final targetScale = _scale.clamp(minimumScale, _maximumScale);
    _scaleTween = Tween<double>(
      begin: _scale,
      end: targetScale,
    );

    _startView = _view;
    _viewTween = RectTween(
      begin: _view,
      end: _getViewInBoundaries(targetScale),
    );

    _settleController.value = 0.0;
    _settleController.animateTo(
      1.0,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 350),
    );
  }

  Rect _getViewInBoundaries(double scale) =>
      Offset(
        max(
          min(_view.left, _area.left * _view.width / scale),
          _area.right * _view.width / scale - 1.0,
        ),
        max(
            min(
              _view.top,
              _area.top * _view.height / scale,
            ),
            _area.bottom * _view.height / scale - 1.0),
      ) &
      _view.size;

  double get _maximumScale => widget.maximumScale;

  double? get _minimumScale {
    final boundaries = _boundaries;
    final image = _image;
    if (boundaries == null || image == null) {
      return null;
    }

    final scaleX = boundaries.width * _area.width / (image.width * _ratio);
    final scaleY = boundaries.height * _area.height / (image.height * _ratio);
    return min(_maximumScale, max(scaleX, scaleY));
  }

  void _activate() {
    _activeController.animateTo(
      1.0,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _deactivate() {
    if (widget.alwaysShowGrid == false) {
      _activeController.animateTo(
        0.0,
        curve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  Size? get _boundaries {
    final context = _globalKey.currentContext;

    if (context == null) {
      return initialBoundaries - const Offset(_kCropHandleSize, _kCropHandleSize) as Size;
    }

    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final bon = size - const Offset(_kCropHandleSize, _kCropHandleSize) as Size;

    return bon;
  }

  Offset? _getLocalPoint(Offset point) {
    final context = _globalKey.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject() as RenderBox;

    return box.globalToLocal(point);
  }

  void _settleAnimationChanged() {
    widget.isCroppingReady(_activeController.value == 0);
    setState(() {
      _scale = _scaleTween.transform(_settleController.value);
      final nextView = _viewTween.transform(_settleController.value);
      if (nextView != null) {
        _view = nextView;
      }
    });
  }

  Rect _calculateDefaultArea({
    required int? imageWidth,
    required int? imageHeight,
    required double viewWidth,
    required double viewHeight,
  }) {
    if (imageWidth == null || imageHeight == null) return Rect.zero;

    double height;
    double width;
    if ((widget.aspectRatio) < 1) {
      height = 1.0;
      width = ((widget.aspectRatio) * imageHeight * viewHeight * height) / imageWidth / viewWidth;
      if (width > 1.0) {
        width = 1.0;
        height = (imageWidth * viewWidth * width) / (imageHeight * viewHeight * (widget.aspectRatio));
      }
    } else {
      width = 1.0;
      height = (imageWidth * viewWidth * width) / (imageHeight * viewHeight * (widget.aspectRatio));
      if (height > 1.0) {
        height = 1.0;
        width = ((widget.aspectRatio) * imageHeight * viewHeight * height) / imageWidth / viewWidth;
      }
    }
    final aspectRatio = _maxAreaWidthMap[widget.aspectRatio];
    if (aspectRatio != null) {
      _maxAreaWidthMap[aspectRatio] = width;
    }
    ui.Rect rect = Rect.fromLTWH((1.0 - width) / 2, (1.0 - height) / 2, width, height);
    return rect;
  }

  void _updateImage(ImageInfo imageInfo, bool synchronousCall) {
    final boundaries = _boundaries;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        final image = imageInfo.image;

        _image = image;
        _scale = imageInfo.scale;
        if (boundaries == null) return;

        _ratio = max(
          boundaries.width / image.width,
          boundaries.height / image.height,
        );

        final viewWidth = boundaries.width / (image.width * _scale * _ratio);
        final viewHeight = boundaries.height / (image.height * _scale * _ratio);
        _area = _calculateDefaultArea(
          viewWidth: viewWidth,
          viewHeight: viewHeight,
          imageWidth: image.width,
          imageHeight: image.height,
        );
        _view = Rect.fromLTWH(
          (viewWidth - 1.0) / 2,
          (viewHeight - 1.0) / 2,
          viewWidth,
          viewHeight,
        );
      });
    });

    WidgetsBinding.instance.ensureVisualUpdate();
  }

  _CropHandleSide _hitCropHandle(Offset? localPoint) {
    final boundaries = _boundaries;
    if (localPoint == null || boundaries == null) {
      return _CropHandleSide.none;
    }

    final viewRect = Rect.fromLTWH(
      boundaries.width * _area.left,
      boundaries.height * _area.top,
      boundaries.width * _area.width,
      boundaries.height * _area.height,
    ).deflate(_kCropHandleSize / 2);

    if (Rect.fromLTWH(
      viewRect.left - _kCropHandleHitSize / 2,
      viewRect.top - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.topLeft;
    }

    if (Rect.fromLTWH(
      viewRect.right - _kCropHandleHitSize / 2,
      viewRect.top - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.topRight;
    }

    if (Rect.fromLTWH(
      viewRect.left - _kCropHandleHitSize / 2,
      viewRect.bottom - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.bottomLeft;
    }

    if (Rect.fromLTWH(
      viewRect.right - _kCropHandleHitSize / 2,
      viewRect.bottom - _kCropHandleHitSize / 2,
      _kCropHandleHitSize,
      _kCropHandleHitSize,
    ).contains(localPoint)) {
      return _CropHandleSide.bottomRight;
    }

    return _CropHandleSide.none;
  }
}

class _CropPainter extends CustomPainter {
  final ui.Image? image;
  final Rect view;
  final double ratio;
  final Rect area;
  final double scale;
  final Color paintColor;
  final ColorFilter colorFilter;
  final double rotationIndex;

  _CropPainter({
    required this.image,
    required this.view,
    required this.ratio,
    required this.area,
    required this.scale,
    required this.paintColor,
    required this.colorFilter,
    required this.rotationIndex,
  });

  @override
  bool shouldRepaint(_CropPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.view != view ||
        oldDelegate.ratio != ratio ||
        oldDelegate.area != area ||
        oldDelegate.scale != scale ||
        oldDelegate.rotationIndex != rotationIndex; // Include rotation index in repaint condition
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _kCropHandleSize / 2,
      _kCropHandleSize / 2,
      size.width - _kCropHandleSize,
      size.height - _kCropHandleSize,
    );
    canvas.save();
    canvas.translate(rect.left, rect.top);

    final paint = Paint()..isAntiAlias = false;

    final imagePaint = Paint()
      ..isAntiAlias = false
      ..colorFilter = colorFilter;

    final image = this.image;
    if (image != null) {
      // Calculate the center point for rotation
      final imageCenter = Offset(
        rect.width / 2,
        rect.height / 2,
      );

      canvas.save();
      canvas.translate(imageCenter.dx, imageCenter.dy);
      canvas.rotate(rotationIndex); // Apply the rotation
      canvas.translate(-imageCenter.dx, -imageCenter.dy);

      final src = Rect.fromLTWH(
        0.0,
        0.0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final dst = Rect.fromLTWH(
        view.left * image.width * scale * ratio,
        view.top * image.height * scale * ratio,
        image.width * scale * ratio,
        image.height * scale * ratio,
      );

      canvas.clipRect(Rect.fromLTWH(0.0, 0.0, rect.width, rect.height));
      canvas.drawImageRect(image, src, dst, imagePaint);
      canvas.restore(); // Restore canvas to remove rotation
    }

    // Use the original paint object for the boundaries and padding space
    paint.color = paintColor;

    final boundaries = Rect.fromLTWH(
      rect.width * area.left,
      rect.height * area.top,
      rect.width * area.width,
      rect.height * area.height,
    );
    canvas.drawRect(Rect.fromLTRB(0.0, 0.0, rect.width, boundaries.top), paint);
    canvas.drawRect(Rect.fromLTRB(0.0, boundaries.bottom, rect.width, rect.height), paint);
    canvas.drawRect(Rect.fromLTRB(0.0, boundaries.top, boundaries.left, boundaries.bottom), paint);
    canvas.drawRect(Rect.fromLTRB(boundaries.right, boundaries.top, rect.width, boundaries.bottom), paint);

    canvas.restore();
  }
}

class _GridCropPainter extends CustomPainter {
  final Rect view;
  final Rect area;
  final double active;
  final Color paintColor;
  final Color gridColor;
  final CropEditImageType type;
  _GridCropPainter({
    required this.type,
    required this.view,
    required this.area,
    required this.active,
    required this.paintColor,
    required this.gridColor,
  });

  @override
  bool shouldRepaint(_GridCropPainter oldDelegate) {
    return oldDelegate.view != view || oldDelegate.area != area || oldDelegate.active != active;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _kCropHandleSize / 2,
      _kCropHandleSize / 2,
      size.width - _kCropHandleSize,
      size.height - _kCropHandleSize,
    );
    canvas.save();
    canvas.translate(rect.left, rect.top);

    final paint = Paint()..isAntiAlias = false;

    paint.color = paintColor;

    final boundaries = Rect.fromLTWH(
      rect.width * area.left,
      rect.height * area.top,
      rect.width * area.width,
      rect.height * area.height,
    );

    if (boundaries.isEmpty == false) _drawGrid(canvas, boundaries);

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Rect boundaries) {
    if (active == 0.0) return;

    final paint = Paint()
      ..isAntiAlias = false
      ..color = gridColor.withOpacity(gridColor.opacity * active)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    if (type == CropEditImageType.normal) {
      path
        ..moveTo(boundaries.left, boundaries.bottom)
        ..lineTo(boundaries.right, boundaries.bottom)
        ..moveTo(boundaries.left, boundaries.top)
        ..lineTo(boundaries.right, boundaries.top);
    }

    for (var column = 1; column < _kCropGridColumnCount; column++) {
      path
        ..moveTo(boundaries.left + column * boundaries.width / _kCropGridColumnCount, boundaries.top)
        ..lineTo(boundaries.left + column * boundaries.width / _kCropGridColumnCount, boundaries.bottom);
    }

    for (var row = 1; row < _kCropGridRowCount; row++) {
      path
        ..moveTo(boundaries.left, boundaries.top + row * boundaries.height / _kCropGridRowCount)
        ..lineTo(boundaries.right, boundaries.top + row * boundaries.height / _kCropGridRowCount);
    }

    canvas.drawPath(path, paint);
  }
}

class _BannerPainter extends CustomPainter {
  final Rect view;
  final Rect area;
  final double active;
  final Color paintColor;

  const _BannerPainter({
    required this.view,
    required this.area,
    required this.active,
    required this.paintColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = paintColor
      ..style = PaintingStyle.fill;

    _drawTopOverlayRectangle(overlayPaint, canvas, size);
    _drawBottomOverlayRectangle(overlayPaint, canvas, size);
  }

  void _drawTopOverlayRectangle(Paint paint, Canvas canvas, Size size) {
    // aspect ratio (3:1)
    final overlayHeight = size.width / 3;

    final topOverlayRect = Rect.fromLTWH(0, 0, size.width, overlayHeight);

    canvas.drawRect(topOverlayRect, paint);
  }

  void _drawBottomOverlayRectangle(Paint paint, Canvas canvas, Size size) {
    // aspect ratio (3:1)
    final overlayHeight = size.width / 3;

    final bottomOverlayRect = Rect.fromLTWH(
      0,
      size.height - overlayHeight,
      size.width,
      overlayHeight,
    );

    canvas.drawRect(bottomOverlayRect, paint);
  }

  @override
  bool shouldRepaint(_BannerPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint paintCircle = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke;

    Paint paintSquare = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset center = Offset(size.width / 2, size.height / 2);

    double circleRadius = size.width / 2;
    double squareSize = size.width;

    Path circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: circleRadius));

    Rect squareRect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );
    Path squarePath = Path()..addRect(squareRect);

    Path differencePath = Path.combine(PathOperation.difference, squarePath, circlePath);

    canvas.drawPath(differencePath, paintSquare);

    canvas.drawPath(circlePath, paintCircle);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
