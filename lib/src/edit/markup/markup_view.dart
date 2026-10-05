import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker_plus/src/core/picker_layout.dart';
import 'package:image_picker_plus/src/core/picker_scope.dart';
import 'package:image_picker_plus/src/edit/edit_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_buttons.dart';
import 'package:image_picker_plus/src/edit/markup/markup_controller.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item.dart';
import 'package:image_picker_plus/src/edit/markup/markup_item_view.dart';
import 'package:image_picker_plus/src/edit/markup/markup_canvas.dart';
import 'package:image_picker_plus/src/edit/markup/pen_controls.dart';
import 'package:image_picker_plus/src/edit/markup/emoji_sheet.dart';
import 'package:image_picker_plus/src/edit/markup/text_editor.dart';
import 'package:image_picker_plus/src/models/edit_state.dart';
import 'package:image_picker_plus/src/widgets/picker_app_bar.dart';

/// the markup page pushed over the edit page, the image cropped like it'll be saved with its markup on top.
class MarkupView extends StatefulWidget {
  final EditController controller;

  const MarkupView({required this.controller, super.key});

  @override
  State<MarkupView> createState() => _MarkupViewState();
}

class _MarkupViewState extends State<MarkupView> {
  final ValueNotifier<(MarkupItem, MarkupItem)?> _moving = ValueNotifier(null);
  final ValueNotifier<StrokeMark?> _active = ValueNotifier(null);

  /// the pointer on screen while a text or emoji is dragged, the delete area shows then.
  final ValueNotifier<Offset?> _dragging = ValueNotifier(null);
  final GlobalKey _deleteKey = GlobalKey();

  /// asked for when the mode opens, the edit page already holds the focus so autofocus wouldn't move it.
  final FocusNode _focus = FocusNode();

  /// the text in the editor, and the one it changes, null for a new one.
  TextMark? _editing;
  TextMark? _editingFrom;

  Color? _color;
  double _width = PenControls.widths[1];
  bool _erasing = false;

  EditController get _controller => widget.controller;
  MarkupController get _markup => _controller.markups[_controller.current.value.id]!;
  Rect get _crop => _controller.crops[_controller.current.value.id]?.value ?? EditState.full;

  @override
  void initState() {
    super.initState();
    _controller.tool.addListener(_onTool);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _onTool();
    });
  }

  @override
  void dispose() {
    _controller.tool.removeListener(_onTool);
    _focus.dispose();
    for (final notifier in [_moving, _active, _dragging]) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _onTool() {
    if (!mounted) return;
    setState(() {});
    switch (_controller.tool.value) {
      case MarkupTool.text:
        _newText();
      case MarkupTool.emoji:
        _pickEmoji();
      case MarkupTool.draw || null:
        break;
    }
  }

  void _newText() {
    final crop = _crop;
    setState(() {
      _editingFrom = null;
      _editing = TextMark(
        text: "",
        color: PickerScope.of(context).settings.markup.colors.first,
        center: crop.center,
        size: 0.08 * crop.width,
        font: DefaultTextStyle.of(context).style.fontFamily,
        direction: Directionality.of(context),
      );
    });
  }

  void _doneText(TextMark? result) {
    final from = _editingFrom;
    if (from != null) {
      result == null ? _markup.remove(from) : _markup.replace(from, result);
    } else if (result != null) {
      _markup.add(result);
    }
    setState(() => _editing = _editingFrom = null);
  }

  Future<void> _pickEmoji() async {
    final emoji = await EmojiSheet.show(context);
    if (emoji == null || !mounted) return;
    final crop = _crop;
    _markup.add(
      TextMark(
        text: emoji,
        color: PickerScope.of(context).settings.markup.colors.first,
        center: crop.center,
        size: 0.15 * crop.width,
        direction: Directionality.of(context),
      ),
    );
  }

  bool _overDelete(Offset pointer) {
    final box = _deleteKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (box.localToGlobal(Offset.zero) & box.size).inflate(8).contains(pointer);
  }

  void _endMove(MarkupItem from, MarkupItem to, Offset pointer) {
    final delete = _dragging.value != null && _overDelete(pointer);
    _moving.value = null;
    _dragging.value = null;
    delete ? _markup.remove(from) : _markup.replace(from, to);
  }

  void _leave() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    final markup = _markup;
    final tool = _controller.tool.value;
    final editing = _editing;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _leave,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): markup.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): markup.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): markup.redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): markup.redo,
      },
      child: Focus(
        focusNode: _focus,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: scope.theme.background,
              appBar: PickerAppBar(
                title: MarkupButtons(controller: _controller),
                closeIcon: Icons.arrow_back_rounded,
                onClose: _leave,
                action: _Actions(markup: markup, onDone: _leave),
              ),
              body: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: MarkupCanvas(
                            controller: _controller,
                            drawing: tool == MarkupTool.draw,
                            moving: _moving,
                            active: _active,
                            editingFrom: _editingFrom,
                            pen: StrokeMark(
                              points: const [],
                              color: _erasing
                                  ? scope.theme.onSurface.withValues(alpha: 0.4)
                                  : _color ?? scope.settings.markup.colors.first,
                              width: _erasing ? PenControls.eraserWidth : _width,
                            ),
                            erasing: _erasing,
                            onTapText: (mark) => setState(() => _editing = _editingFrom = mark),
                            onMove: (mark, to, pointer) {
                              _moving.value = (mark, to);
                              _dragging.value = pointer;
                            },
                            onEnd: _endMove,
                          ),
                        ),
                        if (tool == MarkupTool.draw)
                          PenControls(
                            colors: scope.settings.markup.colors,
                            color: _color ?? scope.settings.markup.colors.first,
                            width: _width,
                            erasing: _erasing,
                            onColor: (color) => setState(() => _color = color),
                            onWidth: (width) => setState(() => _width = width),
                            onErasing: (erasing) => setState(() => _erasing = erasing),
                          ),
                        const SizedBox(height: PickerLayout.padding / 2),
                      ],
                    ),
                    ValueListenableBuilder<Offset?>(
                      valueListenable: _dragging,
                      builder: (context, pointer, _) => pointer == null
                          ? const SizedBox.shrink()
                          : PositionedDirectional(
                              start: 0,
                              end: 0,
                              bottom: PickerLayout.padding * 2,
                              child: Center(
                                child: DeleteArea(key: _deleteKey, over: _overDelete(pointer)),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // over the app bar too, the editor has its own done
            if (editing != null)
              Positioned.fill(
                child: TextEditor(initial: editing, onDone: _doneText),
              ),
          ],
        ),
      ),
    );
  }
}

/// undo, redo and done, at the end of the app bar.
class _Actions extends StatelessWidget {
  final MarkupController markup;
  final VoidCallback onDone;

  const _Actions({required this.markup, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final scope = PickerScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: markup.canUndo,
          builder: (context, can, _) => IconButton(
            onPressed: can ? markup.undo : null,
            tooltip: scope.texts.undo,
            icon: Icon(Icons.undo_rounded, color: can ? scope.theme.onSurface : scope.theme.onSurfaceMuted),
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: markup.canRedo,
          builder: (context, can, _) => IconButton(
            onPressed: can ? markup.redo : null,
            tooltip: scope.texts.redo,
            icon: Icon(Icons.redo_rounded, color: can ? scope.theme.onSurface : scope.theme.onSurfaceMuted),
          ),
        ),
        TextButton(
          onPressed: onDone,
          style: TextButton.styleFrom(
            foregroundColor: scope.theme.accent,
            minimumSize: const Size(PickerLayout.minTouch, PickerLayout.minButtonTouchHeight),
          ),
          child: Text(
            scope.texts.doneEditing,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scope.theme.accent, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
