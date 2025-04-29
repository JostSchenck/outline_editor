import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineSelectionReaction<T extends OutlineTreenode<T>>
    extends EditReaction {
  OutlineSelectionReaction();

  @override
  void modifyContent(EditContext editorContext,
      RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    assert(editorContext.document is OutlineEditableDocument);
    final outlineDoc = editorContext.document as OutlineEditableDocument<T>;

    final event = changeList
        .lastWhereOrNull((editevent) => editevent is SelectionChangeEvent);
    if (event == null) return;
    if ((event as SelectionChangeEvent).newSelection == null) return;
    final selection = event.newSelection!;
    if (selection.isCollapsed) {
      return;
    }
    // if the selection spans the same node, nothing to do
    if (selection.base.nodeId == selection.extent.nodeId) return;
    // if the selection spans more than one node, see if it spans TitleNodes or
    // OutlineTreenodes:
    final baseTreenode = outlineDoc
        .getOutlineTreenodeByDocumentNodeId(selection.base.nodeId)
        .treenode;
    final baseDocNode = outlineDoc.getNodeById(selection.base.nodeId);
    final extentTreenode = outlineDoc
        .getOutlineTreenodeByDocumentNodeId(selection.extent.nodeId)
        .treenode;
    final extentDocNode = outlineDoc.getNodeById(selection.extent.nodeId);
    final selectionAffinity = selection.calculateAffinity(outlineDoc);
    if (baseTreenode.id == extentTreenode.id) {
      // we're in the same treenode. If we span content as well as title, span
      // whole treenode.
      final contentAndTitleSelected =
          (baseDocNode is TitleNode && extentDocNode is! TitleNode) ||
              (baseDocNode is! TitleNode && extentDocNode is TitleNode);
      if (contentAndTitleSelected) {
        stretchSelection(
          requestDispatcher: requestDispatcher,
          document: outlineDoc,
          affinity: selectionAffinity,
          baseTreenode: baseTreenode,
        );
      }
    } else {
      stretchSelection(
        requestDispatcher: requestDispatcher,
        document: outlineDoc,
        affinity: selectionAffinity,
        baseTreenode: baseTreenode,
        extentTreenode: extentTreenode,
      );
    }
  }

  void stretchSelection({
    required RequestDispatcher requestDispatcher,
    required OutlineEditableDocument document,
    required TextAffinity affinity,
    required OutlineTreenode baseTreenode,
    OutlineTreenode? extentTreenode,
  }) {
    final downstream = affinity == TextAffinity.downstream;
    // if these are the same or extent is null, stretch over whole treenode
    if (extentTreenode == null || baseTreenode == extentTreenode) {
      requestDispatcher.execute([
        ChangeSelectionRequest(
            DocumentSelection(
              base: downstream
                  ? baseTreenode.firstPosition
                  : (extentTreenode ?? baseTreenode).lastPosition,
              extent: downstream
                  ? (extentTreenode ?? baseTreenode).lastPosition
                  : baseTreenode.firstPosition,
            ),
            SelectionChangeType.expandSelection,
            'conforming to outline structure')
      ]);
      return;
    }
    OutlineTreenode tn1 = downstream ? baseTreenode : extentTreenode;
    OutlineTreenode tn2 = downstream ? extentTreenode : baseTreenode;

    final lowestCommonAncestor = document
        .getTreenodeByPath(document.getLowestCommonAncestorPath(tn1, tn2));
    tn1 = lowestCommonAncestor == tn1
        ? lowestCommonAncestor
        : lowestCommonAncestor.children.first;
    tn2 = lowestCommonAncestor.lastTreenodeInSubtree;
    requestDispatcher.execute([
      ChangeSelectionRequest(
          DocumentSelection(
            base: downstream ? tn1.firstPosition : tn2.lastPosition,
            extent: downstream ? tn2.lastPosition : tn1.firstPosition,
          ),
          SelectionChangeType.expandSelection,
          'conforming to outline structure')
    ]);
  }
}

// FIXME: prepare for NON-TextNodes in Content!
extension TextNodePositionExtension on TextNode {
  DocumentPosition get firstPosition => DocumentPosition(
      nodeId: id, nodePosition: const TextNodePosition(offset: 0));

  DocumentPosition get lastPosition => DocumentPosition(
      nodeId: id,
      nodePosition: TextNodePosition(offset: text.toPlainText().length));
}

// FIXME: prepare for NON-TextNodes in Content!
extension OutlineTreenodePositionExtension on OutlineTreenode {
  DocumentPosition get firstPosition => DocumentPosition(
      nodeId: titleNode.id, nodePosition: const TextNodePosition(offset: 0));

  DocumentPosition get lastPosition => contentNodes.isEmpty
      ? DocumentPosition(
          nodeId: titleNode.id,
          nodePosition:
              TextNodePosition(offset: titleNode.text.toPlainText().length))
      : DocumentPosition(
          nodeId: contentNodes.last.id,
          nodePosition: TextNodePosition(
              offset:
                  (contentNodes.last as TextNode).text.toPlainText().length),
        );
}
