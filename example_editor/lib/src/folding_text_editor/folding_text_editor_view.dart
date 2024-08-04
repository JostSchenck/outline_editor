import 'package:flutter/material.dart';
import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

class FoldingTextEditorView extends StatefulWidget {
  const FoldingTextEditorView({super.key});

  static const routeName = '/folding_text_editor';

  @override
  State<FoldingTextEditorView> createState() => _FoldingTextEditorViewState();
}

class _FoldingTextEditorViewState extends State<FoldingTextEditorView> {
  // final GlobalKey _docLayoutKey = GlobalKey();

  late ScrollController _scrollController;

  late MutableDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;
  late DocumentStructure _documentStructure;

  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    // FIXME: Probably get from widget or from provider
    _document = MutableDocument(
      nodes: [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('Standard-Dokument, um auszuprobieren, wie ich '
              'einen Outline-Editor auf Basis eines eigenen DocumentLayouts '
              'hinbekomme. '),
          metadata: {
            'depth': 0,
          },
        ),
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('Dies hier ist ein erstes Child.'),
          metadata: {
            'depth': 1,
          },
        ),
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('Dies hier ist ein erstes Enkelkind.'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('Dies hier ist ein zweites Enkelkind.'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText('Dies hier ist ein zweites Child.'),
          metadata: {
            'depth': 1,
          },
        ),
      ],
    );
    _documentStructure = MetadataDepthDocumentStructure(_document);
    _composer = MutableDocumentComposer();
    _editor = Editor(
      editables: {
        Editor.documentKey: _document,
        Editor.composerKey: _composer,
        'structure': _documentStructure,
      },
      requestHandlers: List.from(defaultRequestHandlers),
      reactionPipeline: [
        ...List.from(defaultEditorReactions),
        DocumentStructureReaction(),
      ],
    );
    _editorFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editorFocusNode.dispose();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Folding Text Editor' /*l10n.counterAppBarTitle*/)),
      body: SuperEditor(
        editor: _editor,
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
            ),
      ),
    );
  }
}
