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

    test('OutlineTreeNodes can be retrieved by their path', () {
      prepareVisibilityTestDocument(document);
      expect(document
          .getOutlineTreenodeByPath([0])
          .headNodeId, '1');
      expect(document
          .getOutlineTreenodeByPath([0, 1])
          .headNodeId, '5');
      // and a relative path
      expect(document
          .getOutlineTreenodeByPath([0, 1])
          .getOutlineTreenodeByPath([0])!
          .headNodeId, '6');
    });
  });
}
