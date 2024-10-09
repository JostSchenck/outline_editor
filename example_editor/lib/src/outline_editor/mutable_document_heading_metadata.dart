import 'package:example_editor/src/navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';

class MutableDocumentHeadingMetadataView extends StatefulWidget {
  const MutableDocumentHeadingMetadataView({super.key});

  static const routeName = '/mutable_document_heading_metadata';

  @override
  State<MutableDocumentHeadingMetadataView> createState() => _MutableDocumentHeadingMetadataViewState();
}

class _MutableDocumentHeadingMetadataViewState extends State<MutableDocumentHeadingMetadataView> {
  late ScrollController _scrollController;
  late OutlineHeadingsMutableDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;

  late FocusNode _editorFocusNode;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _document = OutlineHeadingsMutableDocument(nodes: deserializeMarkdownToDocument('''
# Root paragraph
This is a first paragraph ander our root node.
However, there can be many paragraphs
## This is the first child
And a paragraph for it.
## This is the second child
With text following right away
even in another paragraph
### A grand child
Sein Blick ist vom Vorübergehn der Stäbe, so müd geworden, dass er nichts mehr hält.
Ihm ist, als ob es tausend Stäbe gäbe, und hinter tausend Stäben keine Welt
## This is a third child without a paragraph
    ''').toList());
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(document: _document, composer: _composer);
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
          title: const Text('MutableDocument structured by blockType metadata')),
      drawer: const OutlineExampleNavigationDrawer(),
      backgroundColor: Colors.white,
      body: SuperEditor(
        scrollController: _scrollController,
        editor: _editor,
        focusNode: _editorFocusNode,
        plugins: {
          OutlineEditorPlugin(editor: _editor),
        },
        stylesheet: defaultStylesheet,
      ),
    );
  }
}
