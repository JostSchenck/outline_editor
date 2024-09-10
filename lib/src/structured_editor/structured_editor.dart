import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:structured_rich_text_editor/src/document_structure/document_structure.dart';
import 'package:structured_rich_text_editor/src/document_structure/document_structure_reaction.dart';
import 'package:structured_rich_text_editor/src/folding_state/document_folding_state.dart';
import 'package:structured_rich_text_editor/src/layout/_layout.dart';
import 'package:structured_rich_text_editor/src/structured_editor/style.dart';
import 'package:super_editor/super_editor.dart';

/// [StructuredEditor] wraps a [SuperEditor] widget with settings for a
/// "folding" text editing experience, like in outliners. In addition to
/// super editor's standard editables, it expects a [DocumentStructure]
/// implementation that is responsible for providing structure information
/// based on the [Document], and a [DocumentFoldingState], an editable,
/// providing access to and state for fold and unfold operations; these
/// must be provided when instantiating the [Editor].
///
/// The Editor must also have a [DocumentStructureReaction] as the last
/// reaction in its `reactionPipeline`.
class StructuredEditor extends StatefulWidget {
  const StructuredEditor({
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

  @override
  State<StructuredEditor> createState() => _StructuredEditorState();
}

class _StructuredEditorState extends State<StructuredEditor> {
  late GlobalKey _docLayoutKey;

  @override
  void initState() {
    super.initState();
    assert(
        widget.editor.context.findMaybe(documentStructureKey) != null &&
            widget.editor.context.findMaybe(documentFoldingStateKey) != null,
        'The Editor passed to a StructuredEditor has to have a '
        "DocumentStructure object in the list of its editables, but hasn't");
    _docLayoutKey = widget.documentLayoutKey ?? GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return SuperEditor(
      editor: widget.editor,
      scrollController: widget.scrollController,
      stylesheet: widget.stylesheet ?? defaultStructuredEditorStylesheet,
      documentLayoutKey: _docLayoutKey,
      documentLayoutBuilder: ({
        required SingleColumnLayoutPresenter presenter,
        Key? key,
        List<ComponentBuilder> componentBuilders = const [],
        VoidCallback? onBuildScheduled,
        bool showDebugPaint = false,
      }) =>
          SingleColumnFoldingLayout(
        key: key,
        presenter: presenter,
        componentBuilders: componentBuilders,
        onBuildScheduled: onBuildScheduled,
        showDebugPaint: showDebugPaint,
        editor: widget.editor,
      ),
      keyboardActions: widget.keyboardActions ?? defaultKeyboardActions,
      focusNode: widget.focusNode,
      componentBuilders: widget.componentBuilders,
      customStylePhases: widget.customStylePhases,
      documentOverlayBuilders: widget.documentOverlayBuilders,
      documentUnderlayBuilders: widget.documentUnderlayBuilders,
    );
  }
}
