import 'package:example_editor/src/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineTreeDocumentView extends StatefulWidget {
  const OutlineTreeDocumentView({super.key});

  static const routeName = '/outline_tree_document';

  @override
  State<OutlineTreeDocumentView> createState() => _OutlineTreeDocumentViewState();
}

class _OutlineTreeDocumentViewState extends State<OutlineTreeDocumentView> {
  late ScrollController _scrollController;
  late OutlineTreeDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;
  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _document = OutlineTreeDocument();
    _document.root.addChild(
      OutlineTreenode(
        id: '1',
        document: _document,
        documentNodes: [
          ParagraphNode(
              id: '1a',
              text: AttributedText('First Paragraph of a root node')),
          ParagraphNode(
              id: '1b',
              text: AttributedText('Second Paragraph of a root node')),
        ],
        children: [
          OutlineTreenode(
            id: '2',
            document: _document,
            documentNodes: [
              ParagraphNode(
                  id: '2a',
                  text: AttributedText('This is a child tree node')),
              ParagraphNode(
                  id: '2b',
                  text: AttributedText('with its second paragraph')),
            ],
            children: [
              OutlineTreenode(
                id: '2-1',
                document: _document,
                documentNodes: [
                  ParagraphNode(
                      id: '2-1a',
                      text: AttributedText('grand child yay')),
                  ParagraphNode(
                      id: '2-1b',
                      text: AttributedText('still a grand child')),
                ],
                children: [

                ],
              )
            ],
          ),
          OutlineTreenode(
            id: '3',
            document: _document,
            documentNodes: [
              ParagraphNode(
                  id: '3a',
                  text: AttributedText('And another child')),
              ParagraphNode(
                  id: '3b',
                  text: AttributedText('with a second paragraph')),
            ],
            children: [

            ],
          )
        ],
      ),
    );
    _document.root.addChild(
      OutlineTreenode(
        id: '4',
        document: _document,
        documentNodes: [
          ParagraphNode(
              id: '4a',
              text: AttributedText('There can be more than one root node')),
          ParagraphNode(
              id: '4b',
              text: AttributedText('Second Paragraph of another root node')),
        ],
        children: [
          OutlineTreenode(
            id: '5',
            document: _document,
            documentNodes: [
              ParagraphNode(
                  id: '5a',
                  text: AttributedText('This is a child tree node')),
              ParagraphNode(
                  id: '5b',
                  text: AttributedText('with its second paragraph')),
            ],
            children: [
              OutlineTreenode(
                id: '6',
                document: _document,
                documentNodes: [
                  ParagraphNode(
                      id: '6a',
                      text: AttributedText('grand child yay')),
                  ParagraphNode(
                      id: '6b',
                      text: AttributedText('still a grand child')),
                ],
                children: [

                ],
              )
            ],
          ),
        ],
      ),
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
