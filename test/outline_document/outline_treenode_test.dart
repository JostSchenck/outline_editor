import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

import '../common/visibility_test_document.dart';

void main() {
  group('OutlineTreeNode visibility (hiding and collapsing) of nodes', () {
    late OutlineTreeDocument document;

    setUp(() {
      document = getVisibilityTestDocument();
    });

    test(
        'DocumentNodes are hidden when they belong to an OutlineTreeNode that has an ancestor with isCollapsed set to true',
        () {
      expect(document.isVisible('2'), true);
      expect(document.isVisible('3'), false);
      expect(document.isVisible('4'), false);
      expect(document.isVisible('5'), true);
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
                  nodeId: '2', nodePosition: TextNodePosition(offset: 2)))
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
    late OutlineTreeDocument document;

    setUp(() {
      document = OutlineTreeDocument();
      document.root.addChild(OutlineTreenode(id: 'a', document: document));
      document.root.addChild(OutlineTreenode(id: 'b', document: document));
      document.root.addChild(OutlineTreenode(id: 'd', document: document));
      document.root.children[1]
          .addChild(OutlineTreenode(id: 'c', document: document));
    });

    test(
        'OutlineTreeNodes can be added to the document and will turn up in order',
        () {
      expect(
        document.root.children.length,
        3,
        reason: 'wrong number of children',
      );
      expect(
        document.root.children[1].children.length,
        1,
        reason: 'wrong number of children',
      );
      expect(
        document.getOutlineTreenodeByPath([1, 0]).id,
        'c',
        reason: 'added grand child not found by path',
      );
      expect(
        document.root.children[0].parent,
        document.root,
        reason: 'parent not correctly set in added child node',
      );
      expect(
        document.root.children[1].children[0].parent,
        document.root.children[1],
        reason: 'parent not correctly set in added child node',
      );
    });

    test('OutlineTreeNodes can be removed with removeChild', () {
      final child1 = document.root.children[0];
      final child2 = document.root.children[2];
      document.root.removeChild(child1);
      document.root.removeChild(child2);

      expect(document.root.children.length, 1);
    });
  });

  group('OutlineTreeNode addressing nodes by id or path', () {
    late OutlineTreeDocument document;

    setUp(() {
      document = getVisibilityTestDocument();
    });

    test('OutlineTreeNodes can be retrieved by their path', () {
      expect(document.getOutlineTreenodeByPath([0]).titleNode.id, '1');
      expect(document.getOutlineTreenodeByPath([0, 1]).titleNode.id, '5');
      // and a relative path
      expect(
          document
              .getOutlineTreenodeByPath([0, 1])
              .getOutlineTreenodeByPath([0])!
              .titleNode
              .id,
          '6');
    });

    test('OutlineTreeNodes can be retrieved by their treeNodeId', () {
      expect(document.root.getOutlineTreenodeByDocumentNodeId('4')!.path,
          [0, 0, 0, 0]);
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

  group('OutlineTreeNode traversal methods', () {
    late OutlineTreeDocument document;

    setUp(() {
      document = OutlineTreeDocument();
      // will not be purged, although it has no documentNodes, as b2 will not
      // be purged, so it has one child
      document.root.addChild(OutlineTreenode(id: 'a', document: document));
      // will be purged, as it has  empty documentNodes and its only child is purged
      document.root.children[0]
          .addChild(OutlineTreenode(id: 'b', document: document));
      // will be purged as empty documentNodes and no children
      document.root.children[0].children[0]
          .addChild(OutlineTreenode(id: 'c', document: document));
      // will not be purged, because it has document nodes
      document.root.children[0].addChild(OutlineTreenode(
          id: 'b2',
          document: document,
          contentNodes: [
            ParagraphNode(id: 'dn1', text: AttributedText('text'))
          ]));
      // will be purged, as it has empty documentNodes and no children
      document.root.addChild(OutlineTreenode(id: 'd', document: document));
    });

    test(
        'purgeStaleChildren finds all stale children and removes them recursively',
        () {
      expect(document.root.children.length, 1);
      expect(document.root.children[0].id, 'a');
      expect(document.root.children[0].children.length, 1);
      expect(document.root.children[0].children[0].id, 'b2');
      expect(document.root.children[0].children[0].children.length, 0);
    });
  });
}
