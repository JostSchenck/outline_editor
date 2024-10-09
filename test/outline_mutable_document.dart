import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

import 'common/visibility_test_document.dart';


void main() {
  group('OutlineMutableDocument', ()
  {
    late OutlineMutableDocument document;

    setUp(() {
      document = OutlineMutableDocument();
    });

    test('rebuildStructure with empty document', () {
      document.rebuildStructure();
      expect(document.rootNodes, isEmpty);
    });

    test('rebuildStructure with single root node', () {
      document.add(ParagraphNode(
          id: '1',
          metadata: {nodeDepthKey: 0},
          text: AttributedText('asdf asdf')));
      document.rebuildStructure();
      expect(document.rootNodes.length, 1);
      expect(document.rootNodes[0].id, 'tn_1');
    });

    test('rebuildStructure with multiple levels', () {
      document.add(ParagraphNode(
          id: '1',
          text: AttributedText('One more'),
          metadata: {nodeDepthKey: 0}));
      document.add(ParagraphNode(
          id: '2',
          text: AttributedText('Two more'),
          metadata: {nodeDepthKey: 1}));
      document.add(ParagraphNode(
          id: '3',
          text: AttributedText('Three more'),
          metadata: {nodeDepthKey: 1}));
      document.add(ParagraphNode(
          id: '4',
          text: AttributedText('Four more'),
          metadata: {nodeDepthKey: 2}));
      document.rebuildStructure();
      expect(document.rootNodes.length, 1);
      expect(document.rootNodes[0].children.length, 2);
      expect(document.rootNodes[0].children[1].children.length, 1);
    });

    test('rebuildStructure throws exception for illegal depth increase', () {
      document.add(ParagraphNode(
          id: '1',
          text: AttributedText('First node'),
          metadata: {nodeDepthKey: 0}));
      document.add(ParagraphNode(
          id: '2',
          text: AttributedText('Second node'),
          metadata: {nodeDepthKey: 2}));
      expect(() => document.rebuildStructure(), throwsException);
    });

    test('rebuildStructure throws exception for negative depth', () {
      document.add(ParagraphNode(
          id: '1',
          text: AttributedText('Negative depth'),
          metadata: {nodeDepthKey: -1}));
      expect(() => document.rebuildStructure(), throwsException);
    });

    test(
        'rebuildStructure throws exception if document does not start with root node',
            () {
          document.add(ParagraphNode(
              id: '1',
              text: AttributedText('First node'),
              metadata: {nodeDepthKey: 1}));
          expect(() => document.rebuildStructure(), throwsException);
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
        'getLastVisibleNode correctly gives the last visible node starting with the given one', () {
      prepareVisibilityTestDocument(document);
      expect(document
          .getLastVisibleNode(const DocumentPosition(
          nodeId: '1', nodePosition: TextNodePosition(offset: 2)))
          .id, '1');
      expect(document
          .getLastVisibleNode(const DocumentPosition(
          nodeId: '2', nodePosition: TextNodePosition(offset: 2)))
          .id, '2');
      expect(document.getLastVisibleNode(const DocumentPosition(
          nodeId: '3', nodePosition: TextNodePosition(offset: 2))).id, '2');
      expect(document.getLastVisibleNode(const DocumentPosition(
          nodeId: '4', nodePosition: TextNodePosition(offset: 2))).id, '2');
      expect(document.getLastVisibleNode(const DocumentPosition(
          nodeId: '5', nodePosition: TextNodePosition(offset: 2))).id, '5');
      expect(document.getLastVisibleNode(const DocumentPosition(
          nodeId: '6', nodePosition: TextNodePosition(offset: 2))).id, '5');
    });

    test(
        'getNextVisibleNode correctly gives the next visible node starting with the given one', () {
      prepareVisibilityTestDocument(document);
      expect(document
          .getNextVisibleNode(const DocumentPosition(
          nodeId: '1', nodePosition: TextNodePosition(offset: 2)))!
          .id, '1');
      expect(document
          .getNextVisibleNode(const DocumentPosition(
          nodeId: '2', nodePosition: TextNodePosition(offset: 2)))!
          .id, '2');
      expect(document.getNextVisibleNode(const DocumentPosition(
          nodeId: '3', nodePosition: TextNodePosition(offset: 2)))!.id, '5');
      expect(document.getNextVisibleNode(const DocumentPosition(
          nodeId: '4', nodePosition: TextNodePosition(offset: 2)))!.id, '5');
      expect(document.getNextVisibleNode(const DocumentPosition(
          nodeId: '5', nodePosition: TextNodePosition(offset: 2)))!.id, '5');
      expect(document.getNextVisibleNode(const DocumentPosition(
          nodeId: '6', nodePosition: TextNodePosition(offset: 2))), null);
    });
  });
}
