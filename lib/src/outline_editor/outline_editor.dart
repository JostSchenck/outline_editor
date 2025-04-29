import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:outline_editor/outline_editor.dart';

/// [OutlineEditor] wraps a [SuperEditor] widget with settings for a
/// "folding" text editing experience, like in outliners. In addition to
/// super editor's standard editables, it expects a [DocumentStructure]
/// implementation that is responsible for providing structure information
/// based on the [Document], and a [DocumentFoldingState], an editable,
/// providing access to and state for fold and unfold operations; these
/// must be provided when instantiating the [Editor].
///
/// The Editor must also have a [DocumentStructureReaction] as the last
/// reaction in its `reactionPipeline`.
class OutlineEditor<T extends OutlineTreenode<T>> extends StatefulWidget {
  const OutlineEditor({
    super.key,
    required this.scrollController,
    required this.editor,
    this.focusNode,
    this.stylesheet,
    this.documentLayoutKey,
    this.componentBuilders,
    this.customStylePhases = const [],
    this.documentOverlayBuilders = defaultSuperEditorDocumentOverlayBuilders,
    this.documentUnderlayBuilders = const [],
    this.keyboardActions,
    this.defaultTreenodeBuilder = basicOutlineTreenodeBuilder,
  });

  final ScrollController scrollController;
  final Editor editor;
  final FocusNode? focusNode;
  final Stylesheet? stylesheet;
  final GlobalKey? documentLayoutKey;
  final List<ComponentBuilder>? componentBuilders;
  final List<SingleColumnLayoutStylePhase> customStylePhases;
  final List<SuperEditorLayerBuilder> documentOverlayBuilders;
  final List<SuperEditorLayerBuilder> documentUnderlayBuilders;
  final List<DocumentKeyboardAction>? keyboardActions;
  final TreenodeBuilder defaultTreenodeBuilder;

  @override
  State<OutlineEditor<T>> createState() => _OutlineEditorState<T>();
}

class _OutlineEditorState<T extends OutlineTreenode<T>>
    extends State<OutlineEditor<T>> {
  late GlobalKey _docLayoutKey;

  @override
  void initState() {
    super.initState();
    _docLayoutKey = widget.documentLayoutKey ??
        GlobalKey(debugLabel: '_OutlineEditorState._docLayoutKey');
  }

  @override
  Widget build(BuildContext context) {
    return SuperEditor(
      editor: widget.editor,
      scrollController: widget.scrollController,
      stylesheet: widget.stylesheet ?? defaultOutlineEditorStylesheet,
      documentLayoutKey: _docLayoutKey,
      keyboardActions: widget.keyboardActions ?? defaultKeyboardActions,
      focusNode: widget.focusNode,
      componentBuilders: widget.componentBuilders ?? defaultComponentBuilders,
      customStylePhases: widget.customStylePhases,
      documentOverlayBuilders: widget.documentOverlayBuilders,
      documentUnderlayBuilders: widget.documentUnderlayBuilders,
      plugins: {
        OutlineEditorPlugin<T>(
          editor: widget.editor,
          documentLayoutKey: _docLayoutKey,
          defaultTreenodeBuilder: widget.defaultTreenodeBuilder,
        ),
      },
    );
  }
}
