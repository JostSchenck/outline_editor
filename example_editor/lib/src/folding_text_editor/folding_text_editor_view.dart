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
  late DocumentFoldingState _documentFoldingState;

  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    // FIXME: Probably get from widget or from provider
    _document = MutableDocument(
      nodes: [
        ParagraphNode(
          id: 'root_paragraph_0',
          text: AttributedText('Standard-Dokument, um auszuprobieren, wie ich '
              'einen Outline-Editor auf Basis eines eigenen DocumentLayouts '
              'hinbekomme. root_paragraph_0'),
          metadata: {
            'depth': 0,
          },
        ),
        ParagraphNode(
          id: 'child_paragraph_A',
          text: AttributedText(
              'Dies hier ist ein erstes Child. child_paragraph_A'),
          metadata: {
            'depth': 1,
          },
        ),
        ParagraphNode(
          id: 'grand_child_paragraph_A',
          text: AttributedText(
              'Dies hier ist ein erstes Enkelkind. grand_child_paragraph_A'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: 'grand_grand_child_paragraph_A',
          text: AttributedText(
              'Dies hier ist Urenkel. grand_grand_child_paragraph_A'),
          metadata: {
            'depth': 3,
          },
        ),
        ParagraphNode(
          id: 'grand_child_paragraph_B',
          text: AttributedText(
              'Dies hier ist ein zweites Enkelkind. grand_child_paragraph_B'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: 'grand_child_paragraph_C',
          text: AttributedText(
              'Dies hier ist ein drittes Enkelkind. grand_child_paragraph_C'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: 'child_paragraph_B',
          text: AttributedText(
              'Dies hier ist ein zweites Child. child_paragraph_B'),
          metadata: {
            'depth': 1,
          },
        ),
      ],
    );
    _documentStructure = MetadataDepthDocumentStructure(_document);
    _composer = MutableDocumentComposer();
    _documentFoldingState = DocumentFoldingState(documentStructure: _documentStructure);
    _editor = Editor(
      editables: {
        Editor.documentKey: _document,
        Editor.composerKey: _composer,
        documentStructureKey: _documentStructure,
        documentFoldingStateKey: _documentFoldingState,
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
      body: StructuredEditor(
        scrollController: _scrollController,
        editor: _editor,
        focusNode: _editorFocusNode,
      ),
    );
  }
}
