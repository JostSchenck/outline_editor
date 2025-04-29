import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

import '../common/build_test_document.dart';
import '../common/visibility_test_document.dart';

void main() {
  group('OutlineTreeNode visibility (hiding and collapsing) of nodes', () {
    late OutlineEditableDocument document;

    setUp(() {
      document = getVisibilityTestDocument();
    });

    test(
        'DocumentNodes are hidden when they belong to an OutlineTreeNode that has an ancestor with isCollapsed set to true',
        () {
      expect(document.isVisible('2'), false);
      expect(document.isVisible('3'), false);
      expect(document.isVisible('4'), false);
      expect(document.isVisible('5'), false);
      expect(document.isVisible('6'), false);
    });

    test(
        'getLastVisibleNode correctly gives the last visible node starting with the given one, going backwards',
        () {
      expect(
          document
              .getLastVisibleDocumentNode(const DocumentPosition(
                  nodeId: '1', nodePosition: TextNodePosition(offset: 2)))
              .id,
          '1');
      expect(
          document
              .getLastVisibleDocumentNode(const DocumentPosition(
                  nodeId: '2title', nodePosition: TextNodePosition(offset: 2)))
              .id,
          '2');
      expect(
          document
              .getLastVisibleDocumentNode(const DocumentPosition(
                  nodeId: '3', nodePosition: TextNodePosition(offset: 2)))
              .id,
          '2');
      expect(
          document
              .getLastVisibleDocumentNode(const DocumentPosition(
                  nodeId: '4', nodePosition: TextNodePosition(offset: 2)))
              .id,
          '2');
      expect(
          document
              .getLastVisibleDocumentNode(const DocumentPosition(
                  nodeId: '5', nodePosition: TextNodePosition(offset: 2)))
              .id,
          '5');
      expect(
          document
              .getLastVisibleDocumentNode(const DocumentPosition(
                  nodeId: '6', nodePosition: TextNodePosition(offset: 2)))
              .id,
          '5');
    });

    test(
        'getNextVisibleNode correctly gives the next visible node starting with the given one',
        () {
      expect(
          document
              .getNextVisibleDocumentnode(const DocumentPosition(
                  nodeId: '1', nodePosition: TextNodePosition(offset: 2)))!
              .id,
          '1');
      expect(
          document
              .getNextVisibleDocumentnode(const DocumentPosition(
                  nodeId: '2', nodePosition: TextNodePosition(offset: 2)))!
              .id,
          '2');
      expect(
          document
              .getNextVisibleDocumentnode(const DocumentPosition(
                  nodeId: '3', nodePosition: TextNodePosition(offset: 2)))!
              .id,
          '5title');
      expect(
          document
              .getNextVisibleDocumentnode(const DocumentPosition(
                  nodeId: '4', nodePosition: TextNodePosition(offset: 2)))!
              .id,
          '5title');
      expect(
          document
              .getNextVisibleDocumentnode(const DocumentPosition(
                  nodeId: '5', nodePosition: TextNodePosition(offset: 2)))!
              .id,
          '5');
      expect(
          document.getNextVisibleDocumentnode(const DocumentPosition(
              nodeId: '6', nodePosition: TextNodePosition(offset: 2))),
          null);
    });
  });

  group('OutlineTreeNode adding and removing nodes', () {
    late OutlineEditableDocument document;

    setUp(() {
      document = OutlineEditableDocument(
          treenodeBuilder: defaultOutlineTreenodeBuilder);
      document.root = TreeEditor.insertChild(
          parent: document.root,
          child: OutlineTreenode(
            id: 'b',
            titleNode: TitleNode(
              id: 'b-t',
              text: AttributedText(''),
            ),
          ));
      document.root = TreeEditor.insertChild(
          parent: document.root,
          child: OutlineTreenode(
            id: 'a',
            titleNode: TitleNode(
              id: 'a-t',
              text: AttributedText(''),
            ),
          ));
      document.root = TreeEditor.insertChild(
          parent: document.root,
          child: OutlineTreenode(
            id: 'd',
            titleNode: TitleNode(
              id: 'd-t',
              text: AttributedText(''),
            ),
          ));
      document.root = TreeEditor.insertChild(
          parent: document.root,
          child: OutlineTreenode(
            id: 'c',
            titleNode: TitleNode(
              id: 'c-t',
              text: AttributedText(''),
            ),
          ));
    });

    test(
        'OutlineTreeNodes can be added to the document and will turn up in order',
        () {
      expect(
        document.root.children.length,
        4,
        reason: 'wrong number of children',
      );
      // expect(
      //   document.root.children[1].children.length,
      //   1,
      //   reason: 'wrong number of children',
      // );
      // expect(
      //   document.getTreenodeByPath([1, 0]).id,
      //   'c',
      //   reason: 'added grand child not found by path',
      // );
    });

    group('OutlineTreeNode addressing nodes by id or path', () {
      late OutlineEditableDocument document;

      setUp(() {
        document = getVisibilityTestDocument();
        print(document.toPrettyTestString());
      });

      test('OutlineTreeNodes can be retrieved by their path', () {
        expect(document.getTreenodeByPath([0]).titleNode.id, '1title');
        expect(document.getTreenodeByPath([0, 1]).titleNode.id, '5title');
        // and a relative path
        expect(
            document
                .getTreenodeByPath([0, 1])
                .getTreenodeByPath([0])!
                .titleNode
                .id,
            '6title');
      });

      test('OutlineTreeNodes can be retrieved by their treeNodeId', () {
        expect(document.root.getPathTo('tn_4')!, [0, 0, 0, 0]);
      });

      test('DocumentNodes in the document can be retrieved by their id', () {
        expect(
            (document.root.getDocumentNodeById('1')! as ParagraphNode)
                .text
                .toPlainText(),
            'One more');
        expect(
            (document.root.getDocumentNodeById('2')! as ParagraphNode)
                .text
                .toPlainText(),
            'Two more');
        expect(
            (document.root.getDocumentNodeById('5')! as ParagraphNode)
                .text
                .toPlainText(),
            'Another ...');
      });

      test(
          'DocumentNodes in the document can be retrieved by their DocumentNodePath',
          () {
        // expect(actual, matcher);
        // TODO
      });
    });
  });
}
