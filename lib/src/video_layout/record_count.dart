import 'package:image_picker_plus/image_picker_plus.dart';
import 'package:flutter/material.dart';

class RecordCount extends StatefulWidget {
  final ValueNotifier<bool> startVideoCount;
  final ValueNotifier<bool> makeProgressRed;
  final ValueNotifier<bool> clearVideoRecord;
  final AppTheme appTheme;

  const RecordCount({
    super.key,
    required this.appTheme,
    required this.startVideoCount,
    required this.makeProgressRed,
    required this.clearVideoRecord,
  });

  @override
  RecordCountState createState() => RecordCountState();
}

class RecordCountState extends State<RecordCount> with TickerProviderStateMixin {
  late AnimationController controller;
  final ValueNotifier<double> opacityLevel = ValueNotifier(1.0);
  final ValueNotifier<double> progress = ValueNotifier(0);

  bool isPlaying = false;

  String get countText {
    Duration count = controller.duration! * controller.value;
    if (controller.isDismissed) {
      return '0:00';
    } else {
      return '${(count.inMinutes % 60).toString().padLeft(1, '0')}:${(count.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  set setOpacityLevel(double value) {
    if (value == opacityLevel.value) return;
    opacityLevel.value = value;
  }

  set setProgress(double value) {
    if (value == progress.value) return;
    progress.value = value;
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    controller.addListener(() {
      if (controller.isAnimating) {
        setProgress = controller.value;
      } else {
        setProgress = 0;
        isPlaying = false;
      }
    });
  }

  @override
  void didUpdateWidget(RecordCount oldWidget) {
    if (widget.startVideoCount.value) {
      controller.forward(from: controller.value == 1.0 ? 0 : controller.value);
      isPlaying = true;
      setOpacityLevel = opacityLevel.value == 0 ? 1.0 : 0.0;
    } else {
      if (widget.clearVideoRecord.value) {
        widget.clearVideoRecord.value = false;
        controller.reset();
        isPlaying = false;
      } else {
        controller.stop();
        isPlaying = false;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    opacityLevel.dispose();
    progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ValueListenableBuilder(
          valueListenable: progress,
          builder: (context, value, child) => LinearProgressIndicator(
            color: widget.makeProgressRed.value ? Colors.red : widget.appTheme.focusColor,
            backgroundColor: Colors.transparent,
            value: value,
            minHeight: 3,
          ),
        ),
        Visibility(
          visible: widget.startVideoCount.value,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: opacityLevel,
                  builder: (context, value, child) => AnimatedOpacity(
                    opacity: value,
                    duration: const Duration(seconds: 1),
                    child: const Icon(Icons.fiber_manual_record_rounded, color: Colors.red, size: 10),
                    onEnd: () {
                      if (isPlaying) setOpacityLevel = value == 0 ? 1.0 : 0.0;
                    },
                  ),
                ),
                const SizedBox(width: 5),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) => Text(
                    countText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: widget.appTheme.focusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
