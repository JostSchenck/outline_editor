import 'package:collection/collection.dart';
import 'package:outline_editor/outline_editor.dart';

class NodeVisibilityReaction extends EditReaction {
  NodeVisibilityReaction({required this.editor});

  final Editor editor;

  // move the cursor to the last legal and visible position before the node
  // with id nodeId.
  void _collapseAtLastVisibleTextNodePosition(
      RequestDispatcher requestDispatcher,
      OutlineDocument outlineDoc,
      DocumentSelection selection) {
    DocumentNode? lastVisibleNode =
        outlineDoc.getLastVisibleDocumentNode(selection.base);
    while (lastVisibleNode is! TextNode) {
      lastVisibleNode = outlineDoc.getNodeBefore(lastVisibleNode!);
      assert(lastVisibleNode != null,
          'No visible text node found before $selection.base');
    }
    requestDispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
            position: DocumentPosition(
          nodeId: lastVisibleNode.id,
          nodePosition:
              TextNodePosition(offset: lastVisibleNode.text.text.length),
        )),
        SelectionChangeType.placeCaret,
        'the collapsed selection was in a node that is now hidden',
      )
    ]);
  }

  void _collapseAtNextVisibleTextNodePosition(
      RequestDispatcher requestDispatcher,
      OutlineDocument outlineDoc,
      DocumentSelection selection) {
    DocumentNode? nextVisibleNode =
        outlineDoc.getNextVisibleDocumentnode(selection.base);
    while (nextVisibleNode is! TextNode) {
      nextVisibleNode = outlineDoc.getNodeAfter(nextVisibleNode!);
      if (nextVisibleNode == null) {
        // end of visible content reached. Do nothing.
        return;
      }
    }
    requestDispatcher.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
            position: DocumentPosition(
          nodeId: nextVisibleNode.id,
          nodePosition: const TextNodePosition(offset: 0),
        )),
        SelectionChangeType.placeCaret,
        'the collapsed selection was in a node that is now hidden',
      )
    ]);
  }

  @override
  void modifyContent(EditContext editorContext,
      RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    assert(editorContext.document is OutlineDocument);

    final outlineDoc = editorContext.document as OutlineDocument;
    final selection = editorContext.composer.selection;

    if (changeList.any((event) => event is NodeVisibilityChangeEvent)) {
    // if (changeList.firstWhereOrNull((element) => element is NodeVisibilityChangeEvent,)) {
      if (selection == null) return;
      if (selection.isCollapsed) {
        // the selection is collapsed. If the cursor is placed in a node that
        // is now hidden, move it to the end of the last still visible node.
        if (!outlineDoc.isVisible(selection.base.nodeId)) {
          _collapseAtLastVisibleTextNodePosition(
              requestDispatcher, outlineDoc, selection);
        }
        return;
      }
      // so the selection is not collapsed
      if (outlineDoc.isVisible(selection.base.nodeId)) {
        // base is visible ...
        if (outlineDoc.isVisible(selection.extent.nodeId)) {
          // ... extent, too: selection surrounds all the hidden area
          // completely. This is legal.
          return;
        }
        // ... extent not. Selection will be partially hidden at extent end.
        // Collapse at base.
        requestDispatcher.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(position: selection.base),
            SelectionChangeType.placeCaret,
            "the selection's extent was placed in a node that is now hidden",
          )
        ]);
        return;
      }
      // base is not visible ...
      if (outlineDoc.isVisible(selection.extent.nodeId)) {
        // ... but extent is. Selection will be partially hidden at base end.
        // Collapse at extent.
        requestDispatcher.execute([
          ChangeSelectionRequest(
            DocumentSelection.collapsed(position: selection.extent),
            SelectionChangeType.placeCaret,
            "the selection's base was placed in a node that is now hidden",
          )
        ]);
        return;
      }
      // ... and neither is extent. Complete selection hidden, collapse at
      // the last text node position before the hidden area.
      _collapseAtLastVisibleTextNodePosition(
          requestDispatcher, outlineDoc, selection);
    }

    // On SelectionChangeEvents, see if we have to correct because of hidden
    // nodes, eg. when the cursor is moved by the user.
    final selectionEvent =
        changeList.whereType<SelectionChangeEvent>().lastOrNull;
    if (selectionEvent != null) {
      if (selectionEvent.newSelection == null) {
        // lost selection, do nothing
        return;
      }
      final isCollapsed = selectionEvent.newSelection!.isCollapsed;

      if (isCollapsed) {
        if (outlineDoc.isVisible(selectionEvent.newSelection!.base.nodeId)) {
          // cursor is still in visible area, do nothing.
          return;
        } else {
          // cursor moved in invisible area. This should at this point only
          // have happened because of user interaction in form of pushing caret
          // left or right or moving it up and down.
          if (outlineDoc
                  .getNodeIndexById(selectionEvent.oldSelection!.base.nodeId) <
              outlineDoc
                  .getNodeIndexById(selectionEvent.newSelection!.base.nodeId)) {
            // we moved downstream into a hidden node, continue in next visible.
            if (selectionEvent.changeType == SelectionChangeType.pushCaret) {
              // pushCaret means the caret has been moved one to the right
              // TODO: follow SuperEditor issue #2367 whether semantics of
              // SelectionChangeType are going to be revised
              _collapseAtNextVisibleTextNodePosition(
                  requestDispatcher, outlineDoc, selectionEvent.newSelection!);
            } else {
              // no pushCaret, this probably means up or down movement ...
              // TODO: follow SuperEditor issue #2367 whether semantics of
              // SelectionChangeType are going to be revised
              _collapseAtNextVisibleTextNodePosition(
                  requestDispatcher, outlineDoc, selectionEvent.newSelection!);
            }
            // FIXME: This always leads to the beginning of the next visible node.
            // instead, better fire commands
          } else {
            // we moved upstream into a hidden node, continue in visible before.
            // FIXME: Like above, differentiate between left/right and up/down
            _collapseAtLastVisibleTextNodePosition(
                requestDispatcher, outlineDoc, selectionEvent.newSelection!);
          }
        }
      }
    }

    super.modifyContent(editorContext, requestDispatcher, changeList);
  }
}

class NodeVisibilityChangeEvent extends DocumentEdit {
  NodeVisibilityChangeEvent(super.change);

  @override
  String toString() => 'NodeVisibilityChangeEvent -> $change';

// @override
// bool operator ==(Object other) =>
//     identical(this, other) ||
//         other is OutlineStructureChangeEvent &&
//             runtimeType == other.runtimeType &&
//             change == other.change;
}

/// A [DocumentChange] that affects the visibility of nodes due to
/// collapsing/expanding of branches or hiding/unhiding of single nodes.
class NodeVisibilityChange extends DocumentChange {
  const NodeVisibilityChange(
      /*{
    required this.nodeId,
    required this.isVisible,
  }*/
      );

// final String nodeId;
// final bool isVisible;
}
