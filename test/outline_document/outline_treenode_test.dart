import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/outline_document/outline_treenode.dart';

import '../common/visibility_test_document.dart';

void main() {
  group('OutlineTreeNode visibility (hiding and collapsing) of nodes', () {
    late OutlineMutableDocument document;

    setUp(() {
      document = OutlineMutableDocument();
    });

    test(
        'DocumentNodes are hidden when they belong to an OutlineTreeNode that has an ancestor with isCollapsed set to true',
        () {
      prepareVisibilityTestDocument(document);
      expect(document.isVisible('2'), true);
      expect(document.isVisible('3'), false);
      expect(document.isVisible('4'), false);
      expect(document.isVisible('5'), true);
      expect(document.isVisible('6'), false);
    });

    test(
        'getLastVisibleNode correctly gives the last visible node starting with the given one',
        () {
      prepareVisibilityTestDocument(document);
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
      prepareVisibilityTestDocument(document);
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
          '5');
      expect(
          document
              .getNextVisibleDocumentnode(const DocumentPosition(
                  nodeId: '4', nodePosition: TextNodePosition(offset: 2)))!
              .id,
          '5');
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
    late OutlineMutableDocument document;

    setUp(() {
      document = OutlineMutableDocument();
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
        document.getTreenodeByPath([1, 0]).id,
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
    late OutlineMutableDocument document;

    setUp(() {
      document = OutlineMutableDocument();
    });

    test('OutlineTreeNodes can be retrieved by their path', () {
      prepareVisibilityTestDocument(document);
      expect(document.getTreenodeByPath([0]).headNode!.id, '1');
      expect(document.getTreenodeByPath([0, 1]).headNode!.id, '5');
      // and a relative path
      expect(
          document
              .getTreenodeByPath([0, 1])
              .getOutlineTreenodeByPath([0])!
              .headNode!
              .id,
          '6');
    });

    test('OutlineTreeNodes can be retrieved by their treeNodeId', () {
      prepareVisibilityTestDocument(document);
      expect(
          document.root
              .getOutlineTreenodeByPath([0, 1, 0])!
              .documentNodes
              .first!
              .id,
          '6');
      expect(document.root.getOutlineTreenodeForDocumentNodeId('4')!.path,
          [0, 0, 0, 0]);
    });

    test('DocumentNodes in the document can be retrieved by their id', () {
      prepareVisibilityTestDocument(document);
      expect(
          (document.root.getDocumentNodeById('1')! as ParagraphNode).text.text,
          'One more');
      expect(
          (document.root.getDocumentNodeById('2')! as ParagraphNode).text.text,
          'Two more');
      expect(
          (document.root.getDocumentNodeById('5')! as ParagraphNode).text.text,
          'Another ...');
    });

    test(
        'DocumentNodes in the document can be retrieved by their DocumentNodePath',
        () {
      prepareVisibilityTestDocument(document);
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
      document.root.children[0].addChild(OutlineTreenode(id: 'b', document: document));
      // will be purged as empty documentNodes and no children
      document.root.children[0].children[0].addChild(OutlineTreenode(id: 'c', document: document));
      // will not be purged, because it has document nodes
      document.root.children[0].addChild(
          OutlineTreenode(id: 'b2', document: document, documentNodes: [ParagraphNode(id: 'dn1', text: AttributedText('text'))]));
      // will be purged, as it has empty documentNodes and no children
      document.root.addChild(OutlineTreenode(id: 'd', document: document));
    });

    test('purgeStaleChildren finds all stale children and removes them recursively', () {
      document.root.purgeStaleChildren();
      expect(document.root.children.length, 1);
      expect(document.root.children[0].id, 'a');
      expect(document.root.children[0].children.length, 1);
      expect(document.root.children[0].children[0].id, 'b2');
      expect(document.root.children[0].children[0].children.length, 0);
    });
  });


}
