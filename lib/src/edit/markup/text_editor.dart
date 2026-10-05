import 'package:flutter/material.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_painter.dart';
import 'package:image_picker_plus/src/edit/markup/pen_controls.dart';

/// types a new text or changes one, done gives it back, or null when it's empty.
class TextEditor extends StatefulWidget {
  /// the text to change, the editor starts from it.
  final TextMark initial;
  final ValueChanged<TextMark?> onDone;

  const TextEditor({required this.initial, required this.onDone, super.key});

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late final TextEditingController _text = TextEditingController(text: widget.initial.text);
  late TextMark _mark = widget.initial;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _done() {
    final text = _text.text.trim();
    widget.onDone(text.isEmpty ? null : _mark.copyWith(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final markup = scope.settings.markup;
    final fonts = markup.fonts;
    final background = MarkupPainter.backgroundOf(_mark);
    return Material(
      color: scope.theme.scrim,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(
                      () => _mark = _mark.copyWith(
                        background: TextBackground
                            .values[(_mark.background.index + 1) % TextBackground.values.length],
                      ),
                    ),
                    tooltip: scope.texts.textBackground,
                    icon: Icon(Icons.format_color_fill_rounded, color: scope.theme.onSurface),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _done,
                    style: TextButton.styleFrom(foregroundColor: scope.theme.accent),
                    child: Text(scope.texts.doneEditing),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(PickerLayout.padding),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: TextField(
                        controller: _text,
                        autofocus: true,
                        maxLines: null,
                        textAlign: TextAlign.center,
                        textDirection: _mark.direction,
                        cursorColor: scope.theme.accent,
                        style: TextStyle(
                          color: _mark.color,
                          fontSize: 32,
                          fontFamily: _mark.font,
                          height: 1.2,
                        ),
                        decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                      ),
                    ),
                  ),
                ),
              ),
              if (fonts.isNotEmpty)
                SizedBox(
                  height: PickerLayout.minTouch,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final font in [null, ...fonts])
                        Semantics(
                          selected: font == _mark.font,
                          label: scope.texts.font,
                          child: TextButton(
                            onPressed: () => setState(() => _mark = _mark.copyWith(font: () => font)),
                            child: Text(
                              "Aa",
                              style: TextStyle(
                                fontFamily: font,
                                color: font == _mark.font ? scope.theme.accent : scope.theme.onSurface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ColorRow(
                colors: markup.colors,
                selected: _mark.color,
                onChanged: (color) => setState(() => _mark = _mark.copyWith(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
