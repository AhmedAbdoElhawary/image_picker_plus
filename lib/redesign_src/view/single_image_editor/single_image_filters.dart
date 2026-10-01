part of '../edit_media_page.dart';

class _BuildSingleFilters extends StatelessWidget {
  const _BuildSingleFilters({
    required this.selectedImageIndex,
    required this.selectedFilterIndex,
    required this.selectedAspectRatio,
  });

  final int selectedImageIndex;
  final ValueNotifier<int> selectedFilterIndex;
  final ValueNotifier<double> selectedAspectRatio;

  @override
  Widget build(BuildContext context) {
    return BuildFilters(
      selectedFilterImageIndex: selectedImageIndex,
      child: (index) {
        return _BuildSingleSmallFilteredImage(
          index: index,
          selectedImageIndex: selectedImageIndex,
          selectedAspectRatio: selectedAspectRatio,
          selectedFilterIndex: selectedFilterIndex,
        );
      },
    );
  }
}

class _BuildSingleSmallFilteredImage extends StatefulWidget {
  const _BuildSingleSmallFilteredImage({
    required this.selectedImageIndex,
    required this.selectedAspectRatio,
    required this.selectedFilterIndex,
    required this.index,
  });

  final int index;
  final int selectedImageIndex;
  final ValueNotifier<double> selectedAspectRatio;
  final ValueNotifier<int> selectedFilterIndex;

  @override
  State<_BuildSingleSmallFilteredImage> createState() => _BuildSingleSmallFilteredImageState();
}

class _BuildSingleSmallFilteredImageState extends State<_BuildSingleSmallFilteredImage> {
  bool startTap = false;
  @override
  Widget build(BuildContext context) {
    final filter = Filters.list[widget.index];

    return Listener(
      onPointerDown: (details) {
        setState(() {
          startTap = true;
        });
      },
      onPointerUp: (details) {
        setState(() {
          startTap = false;
        });
      },
      child: GestureDetector(
        onTap: () {
          widget.selectedFilterIndex.value = widget.index;
        },
        child: ScalePopupAnimationWidget(
          scaleBigger: false,
          isAnimating: startTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: widget.selectedFilterIndex,
                builder: (context, int selectedFilterImageIndex, child) => Text(
                  filter.filterName,
                  style: TextStyle(
                      fontSize: 12,
                      color: context.getColor(
                        widget.index == selectedFilterImageIndex
                            ? ThemeEnum.focusColor
                            : ThemeEnum.hoverColor,
                      ),
                      fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(height: 5.r),
              SizedBox(
                width: 90.r,
                height: 90.r,
                child: SmallFilteredImage(
                    selectedFilterImageIndex: widget.selectedImageIndex, index: widget.index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
