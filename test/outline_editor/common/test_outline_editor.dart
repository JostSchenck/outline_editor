import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';

import 'visibility_test_document.dart';

class TestOutlineEditor extends StatefulWidget {
  const TestOutlineEditor({
    super.key,
  });

  @override
  State<TestOutlineEditor> createState() => _TestOutlineEditorState();
}

class _TestOutlineEditorState extends State<TestOutlineEditor> {
  late ScrollController _scrollController;
  late OutlineEditableDocument _document;
  late Editor _editor;
  late MutableDocumentComposer _composer;
  late FocusNode _editorFocusNode;
  late GlobalKey _docLayoutKey;

  @override
  void initState() {
    super.initState();
    _document = getVisibilityTestDocument();
    _scrollController = ScrollController();
    _composer = MutableDocumentComposer();
    _editor =
        createDefaultDocumentEditor(document: _document, composer: _composer);
    _editorFocusNode = FocusNode();
    _docLayoutKey = GlobalKey();
  }

  @override
  void dispose() {
    _editorFocusNode.dispose();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: const Text('Outline Editor' /*l10n.counterAppBarTitle*/)),
        backgroundColor: Colors.white,
        body: SuperEditor(
          scrollController: _scrollController,
          editor: _editor,
          focusNode: _editorFocusNode,
          documentLayoutKey: _docLayoutKey,
          plugins: {
            OutlineEditorPlugin(
              editor: _editor,
              documentLayoutKey: _docLayoutKey,
            ),
          },
        ),
      ),
    );
  }
}
