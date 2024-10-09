import 'package:example_editor/src/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';

class MutableDocumentDepthMetadataView extends StatefulWidget {
  const MutableDocumentDepthMetadataView({super.key});

  static const routeName = '/mutable_document_depth_metadata';

  @override
  State<MutableDocumentDepthMetadataView> createState() =>
      _MutableDocumentDepthMetadataViewState();
}

class _MutableDocumentDepthMetadataViewState
    extends State<MutableDocumentDepthMetadataView> {
  late ScrollController _scrollController;
  late OutlineMutableDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;

  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _document = OutlineMutableDocument(
      nodes: [
        ParagraphNode(
          id: 'root_paragraph_0',
          text: AttributedText('Root text node'),
          metadata: {
            'depth': 0,
          },
        ),
        ParagraphNode(
          id: 'root_paragraph_1',
          text: AttributedText('Second paragraph for the root node'),
          metadata: {
            'depth': 0,
          },
        ),
        ParagraphNode(
          id: 'child_paragraph_A',
          text: AttributedText('This is the first child text node.'),
          metadata: {
            'depth': 1,
          },
        ),
        ParagraphNode(
          id: 'child_paragraph_A2',
          text: AttributedText('with another paragraph.'),
          metadata: {
            'depth': 1,
          },
        ),
        ParagraphNode(
          id: 'grand_child_paragraph_A',
          text: AttributedText('A grand child text node'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: 'grand_grand_child_paragraph_A',
          text: AttributedText('and a grand grand child node'),
          metadata: {
            'depth': 3,
          },
        ),
        ParagraphNode(
          id: 'grand_child_paragraph_B',
          text: AttributedText('This is the second grand child'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: 'grand_child_paragraph_C',
          text: AttributedText('It has a second paragraph.'),
          metadata: {
            'depth': 2,
          },
        ),
        ParagraphNode(
          id: 'child_paragraph_B',
          text: AttributedText('Another child ...'),
          metadata: {
            'depth': 1,
          },
        ),
        ParagraphNode(
          id: 'child_paragraph_B2',
          text: AttributedText('... with a second paragraph'),
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
          title: const Text('MutableDocument structured by depth metadata')),
      drawer: const OutlineExampleNavigationDrawer(),
      backgroundColor: Colors.white,
      body: SuperEditor(
        scrollController: _scrollController,
        editor: _editor,
        focusNode: _editorFocusNode,
        plugins: {
          OutlineEditorPlugin(editor: _editor),
        },
        stylesheet: defaultOutlineEditorStylesheet,
      ),
    );
  }
}
