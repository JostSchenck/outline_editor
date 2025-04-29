import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

import '../common/build_test_document.dart';

OutlineEditableDocument<BasicOutlineTreenode> prepareDocument(
    {changeIds = false}) {
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
    late OutlineEditableDocument<BasicOutlineTreenode> outlineTreeDocument;
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
