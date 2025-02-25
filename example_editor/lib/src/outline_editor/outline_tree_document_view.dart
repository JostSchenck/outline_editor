import 'package:example_editor/src/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineTreeDocumentView extends StatefulWidget {
  const OutlineTreeDocumentView({super.key});

  static const routeName = '/outline_tree_document';

  @override
  State<OutlineTreeDocumentView> createState() =>
      _OutlineTreeDocumentViewState();
}

class _OutlineTreeDocumentViewState extends State<OutlineTreeDocumentView> {
  late ScrollController _scrollController;
  late OutlineTreeDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;
  late FocusNode _editorFocusNode;
  late GlobalKey _docLayoutKey;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _document = OutlineTreeDocument();
    _document.root.addChild(
      OutlineTreenode(
        id: '1',
        document: _document,
        titleNode: TitleNode(
            id: '1a', text: AttributedText('First Paragraph of a root node')),
        contentNodes: [
          ParagraphNode(
              id: '1b', text: AttributedText('First Paragraph of a root node')),
          ParagraphNode(
              id: '1c',
              text: AttributedText('Second Paragraph of a root node')),
        ],
        children: [
          OutlineTreenode(
            id: '2',
            document: _document,
            titleNode: TitleNode(
                id: '2a', text: AttributedText('This is a child tree node')),
            contentNodes: [
              ParagraphNode(
                  id: '2b', text: AttributedText('with its first paragraph')),
              ParagraphNode(
                  id: '2c', text: AttributedText('with its second paragraph')),
            ],
            children: [
              OutlineTreenode(
                id: '2-1',
                document: _document,
                titleNode: TitleNode(
                    id: '2-1a', text: AttributedText('grand child yay')),
                contentNodes: [
                  ParagraphNode(
                      id: '2-1b', text: AttributedText('still a grand child')),
                ],
                children: [],
              )
            ],
          ),
          OutlineTreenode(
            id: '3',
            document: _document,
            titleNode:
                TitleNode(id: '3a', text: AttributedText('And another child')),
            contentNodes: [
              ParagraphNode(id: '3b', text: AttributedText('with a paragraph')),
            ],
            children: [],
          )
        ],
      ),
    );
    _document.root.addChild(
      OutlineTreenode(
        id: '4',
        document: _document,
        titleNode: TitleNode(
            id: '4a',
            text: AttributedText('There can be more than one root node')),
        contentNodes: [
          ParagraphNode(
              id: '4b',
              text: AttributedText('although internally there is one root')),
        ],
        children: [
          OutlineTreenode(
            id: '5',
            document: _document,
            titleNode: TitleNode(
                id: '5a', text: AttributedText('This is a child tree node')),
            contentNodes: [
              ParagraphNode(id: '5b', text: AttributedText('with its text')),
            ],
            children: [
              OutlineTreenode(
                id: '6',
                document: _document,
                titleNode: TitleNode(
                    id: '6a', text: AttributedText('grand child yay')),
                contentNodes: [
                  ParagraphNode(
                      id: '6b', text: AttributedText('still a grand child')),
                ],
                children: [],
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
    _docLayoutKey = GlobalKey();
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
        title: const Text('OutlineTreeDocument'),
        actions: [
          IconButton(
              onPressed: () => _editor
                  .execute([HideShowContentNodesRequest(hideContent: true)]),
              icon: const Icon(Icons.arrow_drop_up)),
          IconButton(
              onPressed: () => _editor
                  .execute([HideShowContentNodesRequest(hideContent: false)]),
              icon: const Icon(Icons.arrow_drop_down)),
        ],
      ),
      drawer: const OutlineExampleNavigationDrawer(),
      backgroundColor: Colors.white,
      body: SuperEditor(
        scrollController: _scrollController,
        editor: _editor,
        focusNode: _editorFocusNode,
        documentLayoutKey: _docLayoutKey,
        plugins: {
          OutlineEditorPlugin(
              editor: _editor, documentLayoutKey: _docLayoutKey),
        },
        stylesheet: defaultOutlineEditorStylesheet,
      ),
    );
  }
}
