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
  late OutlineEditableDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;
  late FocusNode _editorFocusNode;
  late GlobalKey _docLayoutKey;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    BasicOutlineTreenode root = basicOutlineTreenodeBuilder(
      id: 'root',
    );
    root = root.copyInsertChild(
      child: BasicOutlineTreenode(
        id: '1',
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
          BasicOutlineTreenode(
            id: '2',
            titleNode: TitleNode(
                id: '2a', text: AttributedText('This is a child tree node')),
            contentNodes: [
              ParagraphNode(
                  id: '2b', text: AttributedText('with its first paragraph')),
              ParagraphNode(
                  id: '2c', text: AttributedText('with its second paragraph')),
            ],
            children: [
              BasicOutlineTreenode(
                id: '2-1',
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
          BasicOutlineTreenode(
            id: '3',
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

    _document = OutlineEditableDocument<BasicOutlineTreenode>(
      treenodeBuilder: basicOutlineTreenodeBuilder,
      logicalRoot: root,
    );

    _composer = MutableDocumentComposer();
    _editor = createDefaultOutlineDocumentEditor(
      document: _document,
      composer: _composer,
      isHistoryEnabled: true,
    );
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
          OutlineEditorPlugin<BasicOutlineTreenode>(
              editor: _editor, documentLayoutKey: _docLayoutKey),
        },
        stylesheet: defaultOutlineEditorStylesheet,
      ),
    );
  }
}
