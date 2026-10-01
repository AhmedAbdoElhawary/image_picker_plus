part of '../edit_media_page.dart';

class _SingleEditImagePage extends StatefulWidget {
  final int selectedImageIndex;
  final File fullImage;
  final img.Image fullImage2;
  final ValueNotifier<int> selectedFilterIndex;
  final ValueNotifier<int> selectedRotationAngle;

  final ValueNotifier<double> selectedAspectRatio;
  final bool onlyOneImage;
  final bool isSingleAppliedImage;
  final CropEditImageType type;
  final String nextText;

  const _SingleEditImagePage({
    required this.selectedRotationAngle,
    required this.selectedImageIndex,
    required this.selectedFilterIndex,
    required this.selectedAspectRatio,
    this.onlyOneImage = false,
    this.isSingleAppliedImage = false,
    this.nextText = StringsManager.done,
    required this.fullImage,
    required this.fullImage2,
    required this.type,
  });
  @override
  State<_SingleEditImagePage> createState() => _SingleEditImagePageState();
}

class _SingleEditImagePageState extends State<_SingleEditImagePage> {
  final GlobalKey<CustomCropperState> cropKey = GlobalKey<CustomCropperState>();
  late ValueNotifier<img.Image> selectedImage2;
  late final StreamController<File> selectedImage = StreamController<File>.broadcast()..add(widget.fullImage);

  @override
  void initState() {
    selectedImage2 = ValueNotifier(widget.fullImage2);

    // some times image need refresh in initial time to appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant _SingleEditImagePage oldWidget) {
    selectedImage2 = ValueNotifier(widget.fullImage2);
    selectedImage.add(widget.fullImage);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.selectedFilterIndex.dispose();
    widget.selectedAspectRatio.dispose();
    widget.selectedRotationAngle.dispose();
    selectedImage.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [_SingleImageNextButton(selectedImage2, cropKey, widget)],
      ),
      body: CustomScrollView(
        // shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAdaptivePaddingLayout(
            sliver: SliverToBoxAdapter(
              child: Stack(
                alignment: AlignmentDirectional.bottomStart,
                children: [
                  _BuildImage(
                    selectedImage: selectedImage,
                    widget: widget,
                    cropKey: cropKey,
                    selectedImageFile: widget.fullImage,
                  ),
                  if (widget.onlyOneImage && widget.type == CropEditImageType.normal)
                    _ExpandedIcon(
                      selectedAspect: widget.selectedAspectRatio.value,
                      switchAspectRatio: () {
                        ImageProcessing.switchTempAspectRatio(widget.selectedAspectRatio);
                      },
                    ),
                  if (widget.type == CropEditImageType.normal)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RotateIconButton(
                            nextRotation: () async {
                              EditMediaViewModel.getInstance().nextTempRotation(
                                  widget.selectedRotationAngle, widget.fullImage2, widget.selectedImageIndex);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _BuildSingleFilters(
              selectedImageIndex: widget.selectedImageIndex,
              selectedFilterIndex: widget.selectedFilterIndex,
              selectedAspectRatio: widget.selectedAspectRatio,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildImage extends StatefulWidget {
  const _BuildImage({
    required this.selectedImage,
    required this.selectedImageFile,
    required this.widget,
    required this.cropKey,
  });

  final File selectedImageFile;
  final _SingleEditImagePage widget;
  final StreamController<File> selectedImage;
  final GlobalKey<CustomCropperState> cropKey;

  @override
  State<_BuildImage> createState() => _BuildImageState();
}

class _BuildImageState extends State<_BuildImage> {
  late File selectedImage = widget.selectedImageFile;
  @override
  void initState() {
    // some times image need refresh in initial time to appear

    WidgetsBinding.instance.addPostFrameCallback((_) {
      super.setState(() {});
    });

    widget.selectedImage.stream.listen(
      (value) {
        selectedImage = value;
        setState(() {});
      },
    );
    super.initState();
  }

  @override
  void setState(fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) super.setState(fn);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: ValueListenableBuilder(
              valueListenable: widget.widget.selectedFilterIndex,
              builder: (context, int selectedFilterIndex, child) => _BuildSingleImage(
                selectedFilterIndex: selectedFilterIndex,
                selectedAspectRatio: widget.widget.selectedAspectRatio,
                index: widget.widget.selectedImageIndex,
                cropKey: widget.cropKey,
                fullImage: selectedImage,
                type: widget.widget.type,
                selectedRotationAngle: widget.widget.selectedRotationAngle,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SingleImageNextButton extends StatelessWidget {
  const _SingleImageNextButton(this.selectedImage2, this.cropKey, this.widget);
  final ValueNotifier<img.Image> selectedImage2;
  final GlobalKey<CustomCropperState> cropKey;
  final _SingleEditImagePage widget;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStatePropertyAll(
                context.getColor(ThemeEnum.transparentColor),
              ),
            ),
            onPressed: () async {
              await EditMediaViewModel.getInstance().onTapDoneForSingleImage(
                context,
                imageIndex: widget.selectedImageIndex,
                cropKey: cropKey,
                filter: widget.selectedFilterIndex.value,
                angle: widget.selectedRotationAngle.value,
                isOnlySelectedImage: widget.onlyOneImage,
                aspectRatio: widget.selectedAspectRatio.value,
                srcImage: selectedImage2.value,
              );
            },
            child: Text(
              widget.isSingleAppliedImage ? StringsManager.apply : widget.nextText,
              style: TextStyle(color: context.getColor(ThemeEnum.blueColor), fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildSingleImage extends StatefulWidget {
  const _BuildSingleImage({
    required this.type,
    required this.index,
    required this.cropKey,
    required this.fullImage,
    required this.selectedFilterIndex,
    required this.selectedAspectRatio,
    required this.selectedRotationAngle,
  });
  final ValueNotifier<double> selectedAspectRatio;
  final GlobalKey<CustomCropperState> cropKey;
  final int selectedFilterIndex;
  final File fullImage;
  final int index;
  final CropEditImageType type;
  final ValueNotifier<int> selectedRotationAngle;

  @override
  State<_BuildSingleImage> createState() => _BuildSingleImageState();
}

class _BuildSingleImageState extends State<_BuildSingleImage> {
  @override
  Widget build(BuildContext context) {
    final controller = EditMediaViewModel.getInstance();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final colored = Filters.list[widget.selectedFilterIndex].matrix;

        return ValueListenableBuilder(
          valueListenable: widget.selectedRotationAngle,
          builder: (context, rotateAngle, child) => ValueListenableBuilder(
            valueListenable: widget.selectedAspectRatio,
            builder: (context, double aspectRatio, child) => CustomCropper(
              type: widget.type,
              image: widget.fullImage,
              aspectRatio: aspectRatio,
              rotateAngle: rotateAngle,
              key: widget.cropKey,
              initialBoundaries: size,
              colorMatrix: colored,
              paintColor: context.getColor(ThemeEnum.primaryColor),
              gridColor: context.getColor(ThemeEnum.whiteD7Color),
              overlayColor: context.getColor(ThemeEnum.cropGreyOp25),
              isCroppingReady: controller.setCroppingReady,
            ),
          ),
        );
      },
    );
  }
}
