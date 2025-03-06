import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

OutlineTreeDocument prepareDocument({changeIds = false}) {
  final outlineTreeDocument =
      OutlineTreeDocument(root: OutlineTreenode(id: 'root'));
  outlineTreeDocument.root.addChild(
    OutlineTreenode(
      id: changeIds ? 'asdf1' : '1',
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
  outlineTreeDocument.root.addChild(
    OutlineTreenode(
      id: changeIds ? 'asdf4' : '4',
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
    late OutlineTreeDocument outlineTreeDocument;

    setUp(() {
      outlineTreeDocument = prepareDocument();
    });

    test('nodeCount returns correct node cound', () {
      expect(outlineTreeDocument.nodeCount, 21);
    });

    test('hasEquivalent content ignores IDs', () {
      OutlineTreeDocument outlineTreeDocument2 =
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
    late OutlineTreeDocument outlineTreeDocument;
    setUp(() {
      outlineTreeDocument = prepareDocument();
    });

    test(
        'when nodes are collapse, child nodes and their document nodes are hidden',
        () {
      outlineTreeDocument.getOutlineTreenodeByPath([0, 0]).isCollapsed = true;
      expect(outlineTreeDocument.getOutlineTreenodeByPath([0, 0]).isCollapsed,
          true);
      expect(outlineTreeDocument.isVisible('2-1b'), false);
      expect(outlineTreeDocument.isVisible('2b'), true);
      expect(outlineTreeDocument.isVisible('1a'), true);
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
