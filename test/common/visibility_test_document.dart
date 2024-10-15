import 'package:outline_editor/src/outline_document/outline_mutable_document.dart';
import 'package:outline_editor/src/outline_document/outline_treenode.dart';
import 'package:super_editor/super_editor.dart';

void prepareVisibilityTestDocument(OutlineMutableDocument document) {
  document.add(ParagraphNode(
      id: '1',
      text: AttributedText('One more'),
      metadata: {nodeDepthKey: 1}));
  document.add(ParagraphNode(
      id: '2',
      text: AttributedText('Two more'),
      metadata: {nodeDepthKey: 2, isCollapsedKey: true}));
  document.add(ParagraphNode(
      id: '3',
      text: AttributedText('Three more'),
      metadata: {nodeDepthKey: 3})); // should be hidden
  document.add(ParagraphNode(
      id: '4',
      text: AttributedText('Four more'),
      metadata: {nodeDepthKey: 4})); // should be hidden
  document.add(ParagraphNode(
      id: '5',
      text: AttributedText('Another ...'),
      metadata: {nodeDepthKey: 2, isCollapsedKey: true}));
  document.add(ParagraphNode(
      id: '6',
      text: AttributedText('and another'),
      metadata: {nodeDepthKey: 3})); // should be hidden
  document.rebuildStructure();
}
