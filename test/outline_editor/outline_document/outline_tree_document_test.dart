import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

import '../common/build_test_document.dart';

OutlineEditableDocument prepareDocument({changeIds = false}) {
  return buildTestDocumentFromString('''
  root:root
    1:titel 1
      > 1a:First Paragraph of a root node
      > 1b:Second Paragraph of a root node
      2:titel 2
        > 2a:This is a child tree node
        > 2b:with its second paragraph
        2-1:titel 2-1
          > 2-1a:grand child yay
          > 2-1b:still a grand child
      3:titel 3
        > 3a:and another child
        > 3b:with its second paragraph
    4:titel 4
      > 4a:There can be more than one root node
      > 4b:Second Paragraph of another root node
      5:titel 5
        > 5a:This is a child tree node
        > 5b:with its second paragraph
        6:titel 6
          > 6-1a:grand child yay
          > 6-1b:still a grand child
          
  ''');

  final outlineTreeDocument = OutlineEditableDocument(
      treenodeBuilder:
          defaultOutlineTreenodeBuilder /*root: OutlineTreenode(id: 'root')*/);
  outlineTreeDocument.root = TreeEditor.insertChild(
    parent: outlineTreeDocument.root,
    child: OutlineTreenode(
      id: changeIds ? 'asdf1' : '1',
      titleNode: TitleNode(id: '1-t', text: AttributedText('titel 1')),
      contentNodes: [
        ParagraphNode(
            id: changeIds ? 'asdf1a' : '1a',
            text: AttributedText('First Paragraph of a root node')),
        ParagraphNode(
            id: changeIds ? 'asdf1b' : '1b',
            text: AttributedText('Second Paragraph of a root node')),
      ],
      children: [
        OutlineTreenode(
          id: changeIds ? 'asdf2' : '2',
          titleNode: TitleNode(id: '2-t', text: AttributedText('titel 2')),
          contentNodes: [
            ParagraphNode(
                id: changeIds ? 'asdf2a' : '2a',
                text: AttributedText('This is a child tree node')),
            ParagraphNode(
                id: changeIds ? 'asdf2b' : '2b',
                text: AttributedText('with its second paragraph')),
          ],
          children: [
            OutlineTreenode(
              id: changeIds ? 'asdf2-1' : '2-1',
              titleNode:
                  TitleNode(id: '2-1-t', text: AttributedText('titel 2-1')),
              contentNodes: [
                ParagraphNode(
                    id: changeIds ? 'asdf2-1a' : '2-1a',
                    text: AttributedText('grand child yay')),
                ParagraphNode(
                    id: changeIds ? 'asdf2-1b' : '2-1b',
                    text: AttributedText('still a grand child')),
              ],
              children: [],
            )
          ],
        ),
        OutlineTreenode(
          id: changeIds ? 'asdf3' : '3',
          titleNode: TitleNode(id: '3-t', text: AttributedText('titel 3')),
          contentNodes: [
            ParagraphNode(
                id: changeIds ? 'asdf3a' : '3a',
                text: AttributedText('And another child')),
            ParagraphNode(
                id: changeIds ? 'asdf3b' : '3b',
                text: AttributedText('with a second paragraph')),
          ],
          children: [],
        )
      ],
    ),
  );
  outlineTreeDocument.root = TreeEditor.insertChild(
    parent: outlineTreeDocument.root,
    child: OutlineTreenode(
      id: changeIds ? 'asdf4' : '4',
      titleNode: TitleNode(id: '4-t', text: AttributedText('titel 4')),
      contentNodes: [
        ParagraphNode(
            id: changeIds ? 'asdf4a' : '4a',
            text: AttributedText('There can be more than one root node')),
        ParagraphNode(
            id: changeIds ? 'asdf4b' : '4b',
            text: AttributedText('Second Paragraph of another root node')),
      ],
      children: [
        OutlineTreenode(
          id: changeIds ? 'asdf5' : '5',
          titleNode: TitleNode(id: '5-t', text: AttributedText('titel 5')),
          contentNodes: [
            ParagraphNode(
                id: changeIds ? 'asdf5a' : '5a',
                text: AttributedText('This is a child tree node')),
            ParagraphNode(
                id: changeIds ? 'asdf5b' : '5b',
                text: AttributedText('with its second paragraph')),
          ],
          children: [
            OutlineTreenode(
              id: changeIds ? 'asdf6' : '6',
              titleNode: TitleNode(id: '6-t', text: AttributedText('titel 6')),
              contentNodes: [
                ParagraphNode(
                    id: changeIds ? 'asdf6a' : '6a',
                    text: AttributedText('grand child yay')),
                ParagraphNode(
                    id: changeIds ? 'asdf6b' : '6b',
                    text: AttributedText('still a grand child')),
              ],
              children: [],
            )
          ],
        ),
      ],
    ),
  );
  return outlineTreeDocument;
}

main() {
  group('OutlineTreeDocument nodes', () {
    late OutlineEditableDocument outlineTreeDocument;

    setUp(() {
      outlineTreeDocument = prepareDocument();
    });

    test('nodeCount returns correct node cound', () {
      expect(outlineTreeDocument.nodeCount, 21);
    });

    test('hasEquivalent content ignores IDs', () {
      OutlineEditableDocument outlineTreeDocument2 =
          prepareDocument(changeIds: true);
      expect(
          outlineTreeDocument.hasEquivalentContent(outlineTreeDocument2), true);
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });
  });

  group('OutlineTreeDocument retrieving nodes', () {
    late OutlineEditableDocument outlineTreeDocument;
    setUp(() {
      outlineTreeDocument = prepareDocument();
    });

    test(
        'when nodes are collapsed, child nodes and their document nodes are hidden',
        () {
      outlineTreeDocument.root = outlineTreeDocument.root.replaceTreenodeById(
        outlineTreeDocument.getTreenodeById('1').id,
        (p) => p.copyWith(isCollapsed: true),
      );

      expect(outlineTreeDocument.getTreenodeById('1').isCollapsed, true);
      expect(outlineTreeDocument.isVisible('2-1b'), false);
      expect(outlineTreeDocument.isVisible('1b'), false);
      expect(outlineTreeDocument.isVisible('1a'), false);
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });
  });

  group('OutlineTreeDocument adding and removing nodes', () {
    setUp(() {});

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });
  });

  group('OutlineTreeDocument moving and replacing nodes', () {
    setUp(() {});

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });

    test('', () {
      // TODO
    });
  });
}
