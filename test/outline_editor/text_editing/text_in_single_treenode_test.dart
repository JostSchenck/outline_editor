import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:outline_editor/outline_editor.dart';

import '../supereditor_test_tools.dart';

void main() {
  group('outline_editor text in one treenode >', () {
    testWidgetsOnWindowsAndLinux(
      'create ParagraphNodes from TitleNode and other ParagraphNodes',
      (tester) async {
        final context = await tester //
            .createDocument()
            .withOnlyTitleEmptyDoc()
            .withSelection(DocumentSelection(
              base: DocumentPosition(
                  nodeId: 'title1', nodePosition: TextNodePosition(offset: 0)),
              extent: DocumentPosition(
                  nodeId: 'title1', nodePosition: TextNodePosition(offset: 0)),
            ))
            .autoFocus(true)
            .pump();
        final doc =
            context.findEditContext().document as OutlineEditableDocument;
        expect(doc.nodeCount, 1,
            reason:
                'Expected only a single node (title node) in start of test');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
        expect(doc.nodeCount, 2,
            reason:
                'After pressing enter, a document node should have been added and 2 nodes be there');
        expect(doc.root.children.length, 1,
            reason:
                'After adding a document node, there should still be only one root treenode');
        expect(doc.root.children[0].titleNode.text.isEmpty, isTrue,
            reason: 'Title node should be empty');
        expect(doc.root.children[0].contentNodes.length, 1,
            reason: 'Only one paragraph node should have been added');
        expect(
            (doc.root.children[0].contentNodes[0] as ParagraphNode)
                .text
                .isEmpty,
            isTrue);
      },
    );
    testWidgetsOnWindowsAndLinux(
      'Backspace properly deletes ParagraphNodes or whole Treenodes when empty',
      (tester) async {
        final context = await tester //
            .createDocument()
            .withTwoEmptyParagraphs()
            .withSelection(DocumentSelection(
              base: DocumentPosition(
                  nodeId: 'title1', nodePosition: TextNodePosition(offset: 0)),
              extent: DocumentPosition(
                  nodeId: 'title1', nodePosition: TextNodePosition(offset: 0)),
            ))
            .autoFocus(true)
            .pump();
        final doc =
            context.findEditContext().document as OutlineEditableDocument;
        context.composer.setSelectionWithReason(DocumentSelection(
            base: DocumentPosition(
                nodeId: 'par2', nodePosition: TextNodePosition(offset: 0)),
            extent: DocumentPosition(
                nodeId: 'par2', nodePosition: TextNodePosition(offset: 0))));
        expect(doc.nodeCount, 4, reason: 'Must start with 4 empty paragraphs');
        expect(doc.root.children.length, 2,
            reason: 'Must start with two root nodes');
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        expect(doc.root.children[1].contentNodes.isEmpty, isTrue,
            reason: 'Should have deleted second paragraph');
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        expect(doc.root.children.length, 1,
            reason: 'Should have deleted second root treenode');
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        expect(doc.root.children[0].contentNodes.isEmpty, isTrue,
            reason: 'Should have deleted first paragraph');
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        expect(doc.nodeCount, 1,
            reason:
                'pressing backspace again should have done nothing if this is the last title node left');
      },
    );
  });
  test('Beispieltest', () {
    expect(1 + 1, equals(2));
  });
}

Future<void> _pumpApp(
    WidgetTester tester /*, TextInputSource inputSource*/) async {
  await tester //
      .createDocument()
      .withOnlyTitleEmptyDoc()
      // .withInputSource(inputSource)
      .withCustomWidgetTreeBuilder((superEditor) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // Add focusable widgets before and after SuperEditor so that we
            // catch any keys that try to move focus forward or backward.
            const Focus(child: SizedBox(width: double.infinity, height: 54)),
            Expanded(
              child: superEditor,
            ),
            const Focus(child: SizedBox(width: double.infinity, height: 54)),
          ],
        ),
      ),
    );
  }).pump();
}
