import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// writes build/scroll_timeline.timeline_summary.json and build/gallery_numbers.json
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final timeline = driver.Timeline.fromJson(data["scroll_timeline"] as Map<String, dynamic>);
    final summary = driver.TimelineSummary.summarize(timeline);
    await summary.writeTimelineToFile("scroll_timeline", pretty: true, includeSummary: true);

    final frames = summary.countFrames();
    final missed = summary.computeMissedFrameRasterizerBudgetCount() + summary.computeMissedFrameBuildBudgetCount();
    final numbers = {
      "first_thumbnail_ms": data["first_thumbnail_ms"],
      "frames": frames,
      "missed_frames_percent": frames == 0 ? 0 : missed * 100 / frames,
      "rss_before_mb": data["rss_before_mb"],
      "rss_after_mb": data["rss_after_mb"],
    };
    await File("build/gallery_numbers.json").writeAsString(const JsonEncoder.withIndent("  ").convert(numbers));
    stdout.writeln(numbers);
  },
);
