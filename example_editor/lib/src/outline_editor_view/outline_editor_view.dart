import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineEditorView extends StatefulWidget {
  const OutlineEditorView({super.key});

  static const routeName = '/outline_editor';

  @override
  State<OutlineEditorView> createState() => _OutlineEditorViewState();
}

class _OutlineEditorViewState extends State<OutlineEditorView> {
  // final GlobalKey _docLayoutKey = GlobalKey();

  late ScrollController _scrollController;

  late OutlineMutableDocumentByNodeDepthMetadata _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;

  // late DocumentFoldingState _documentFoldingState;

  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _document = OutlineMutableDocumentByNodeDepthMetadata(
      nodes: [
        ParagraphNode(
          id: 'root_paragraph_0',
          text: AttributedText('Standard-Dokument, um auszuprobieren, wie ich '
              'einen Outline-Editor auf Basis eines eigenen DocumentLayouts '
              'hinbekomme. root_paragraph_0'),
          metadata: {
            'blockType': paragraphAttribution,
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
    _composer = MutableDocumentComposer();
    _editor =
        createDefaultDocumentEditor(document: _document, composer: _composer);
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
      backgroundColor: Colors.white,
      body: SuperEditor(
        scrollController: _scrollController,
        editor: _editor,
        focusNode: _editorFocusNode,
        plugins: const {
          OutlineEditorPlugin(),
        },
      ),
    );
  }
}
