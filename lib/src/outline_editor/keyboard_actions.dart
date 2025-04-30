import 'dart:math';

import 'package:flutter/services.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/move_outline_treenode.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/reactions/outline_selection_reaction.dart';
import 'package:outline_editor/src/util/logging.dart';
// parts copied from super_editor LICENSE

/// Undoes the most recent change within the [Editor].
ExecutionInstruction undoWhenCmdZOrCtrlZIsPressed({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.keyZ ||
      !keyEvent.isPrimaryShortcutKeyPressed ||
      HardwareKeyboard.instance.isShiftPressed) {
    return ExecutionInstruction.continueExecution;
  }

  editContext.editor.undo();

  return ExecutionInstruction.haltExecution;
}

/// delete treenodes, if the selection spans whole treenodes; if not, return
/// false, so the calling action can decide on passing on or halting.
bool _deleteSelectedTreenodes<T extends OutlineTreenode<T>>(
    OutlineEditableDocument<T> outlineDoc,
    DocumentSelection selection,
    SuperEditorContext editContext) {
  if (selection.isCollapsed) return false;
  final tn1 =
      outlineDoc.getTreenodeWithPathByDocumentNodeId(selection.base.nodeId);
  final tn2 =
      outlineDoc.getTreenodeWithPathByDocumentNodeId(selection.extent.nodeId);

  if ((selection.base.isEquivalentTo(tn1.treenode.firstPosition) &&
          selection.extent.isEquivalentTo(tn2.treenode.lastPosition)) ||
      (selection.extent.isEquivalentTo(tn2.treenode.firstPosition) &&
          selection.base.isEquivalentTo(tn1.treenode.lastPosition))) {
    // whole treenodes are selected; delete a region.
    final flatList = outlineDoc.root.subtreeList;
    int index1 = flatList.indexWhere((treenode) => treenode == tn1.treenode);
    int index2 = flatList.indexWhere((treenode) => treenode == tn2.treenode);
    final deleteList =
        flatList.sublist(min(index1, index2), max(index1, index2) + 1).reversed;
    final parent = outlineDoc.root.getParentOf(deleteList.last.id)!;
    final childIndex = parent.children.indexOf(deleteList.last);
    final newEmptyNode = outlineDoc.treenodeBuilder(id: uuid.v4()) as T;
    editContext.editor.execute([
      ...deleteList.map((treenode) =>
          DeleteOutlineTreenodeRequest(outlineTreenodeId: treenode.id)),
      InsertOutlineTreenodeRequest<T>(
        existingTreenodeId: parent.id,
        newTreenode: newEmptyNode,
        createChild: true,
        treenodeIndex: childIndex,
      ),
      ChangeSelectionRequest(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: newEmptyNode.titleNode.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
          SelectionChangeType.deleteContent,
          'deleted whole treenodes'),
    ]);
    return true;
  } else {
    return false;
  }
}

ExecutionInstruction
    backspaceSpecialCasesInOutlineTreeDocument<T extends OutlineTreenode<T>>({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  final outlineDoc = editContext.document as OutlineEditableDocument<T>;
  final selection = editContext.composer.selection;

  if (selection == null) return ExecutionInstruction.continueExecution;

  if (!selection.isCollapsed) {
    if (_deleteSelectedTreenodes<T>(outlineDoc, selection, editContext)) {
      return ExecutionInstruction.haltExecution;
    } else {
      return ExecutionInstruction.continueExecution;
    }
  }

  // selection is collapsed
  final outlineNodeResult =
      outlineDoc.getTreenodeForDocumentNodeId(selection.base.nodeId);
  if (selection.base.nodePosition is! TextNodePosition) {
    return ExecutionInstruction.continueExecution;
  }
  final textNodePosition = selection.base.nodePosition as TextNodePosition;

  // we only care, if the cursor is at the start of a text node
  if (textNodePosition.offset != 0) {
    return ExecutionInstruction.continueExecution;
  }
  final textNode = outlineDoc.getNodeById(selection.base.nodeId)!;

  if (textNode is TitleNode) {
    // if at the beginning of a non-empty title node, just move caret to the end of the
    // preceding node. If the title node is empty, merge treenodes.
    final nodeBefore = outlineDoc.getNodeBefore(textNode);
    if (nodeBefore == null || nodeBefore is! TextNode) {
      return ExecutionInstruction.haltExecution;
    }
    final mergeNodes = outlineNodeResult.treenode.isConsideredEmpty ||
        outlineNodeResult.treenode.titleNode.text.toPlainText().isEmpty;
    final treenodeBefore = mergeNodes
        ? outlineDoc.getTreenodeBeforeTreenode(outlineNodeResult.treenode.id)
        : null;
    if (mergeNodes && treenodeBefore == null) {
      return ExecutionInstruction.haltExecution;
    }

    editContext.editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
            position: DocumentPosition(
          nodeId: nodeBefore.id,
          nodePosition:
              TextNodePosition(offset: nodeBefore.text.toPlainText().length),
        )),
        SelectionChangeType.placeCaret,
        'moved caret on backspace without deleting anything',
      ),
      if (mergeNodes)
        MergeOutlineTreenodesRequest(
          treenodeMergedIntoId: treenodeBefore!.id,
          mergedTreenodeId: outlineNodeResult.treenode.id,
        ),
    ]);
    return ExecutionInstruction.haltExecution;
  } else {
    final nodeBefore = outlineDoc.getNodeBefore(textNode);
    if (nodeBefore is TitleNode) {
      editContext.editor.execute([
        ChangeSelectionRequest(
          DocumentSelection.collapsed(
              position: DocumentPosition(
                  nodeId: nodeBefore.id,
                  nodePosition: TextNodePosition(
                      offset: nodeBefore.text.toPlainText().length))),
          SelectionChangeType.deleteContent,
          'Backspace pressed',
        ),
        // delete empty paragraph on backspace
        if ((textNode as TextNode).text.toPlainText().isEmpty)
          DeleteNodeRequest(nodeId: textNode.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    // simple DocumentNode in content -- let SuperEditor do the rest
    return ExecutionInstruction.continueExecution;
  }
}

ExecutionInstruction
    deleteSpecialCasesInOutlineTreeDocument<T extends OutlineTreenode<T>>({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.delete) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) return ExecutionInstruction.continueExecution;
  final outlineDoc = editContext.document as OutlineEditableDocument<T>;

  if (!selection.isCollapsed) {
    if (_deleteSelectedTreenodes<T>(outlineDoc, selection, editContext)) {
      return ExecutionInstruction.haltExecution;
    } else {
      return ExecutionInstruction.continueExecution;
    }
  }

  final outlineNodeResult =
      outlineDoc.getTreenodeForDocumentNodeId(selection.base.nodeId);
  if (selection.base.nodePosition is! TextNodePosition) {
    return ExecutionInstruction.continueExecution;
  }
  final textNodePosition = selection.base.nodePosition as TextNodePosition;
  final textNode = outlineDoc.getNode(selection.base) as TextNode;
  // we only care, if the cursor is at the end of a text node
  if (textNodePosition.offset != textNode.text.toPlainText().length) {
    return ExecutionInstruction.continueExecution;
  }

  final nodeAfter = outlineDoc.getNodeAfter(textNode);
  if (nodeAfter == null || nodeAfter is! TextNode) {
    return ExecutionInstruction.haltExecution;
  }
  if (textNode is TitleNode) {
    // if at the end of a non-empty TitleNode, just move caret to the
    // beginning of the following node. If the treenode is considered empty,
    // delete it (possibly lifting children up in the hierarchy).
    editContext.editor.execute([
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
            position: DocumentPosition(
          nodeId: nodeAfter.id,
          nodePosition: const TextNodePosition(offset: 0),
        )),
        SelectionChangeType.placeCaret,
        'moved caret on delete without deleting anything',
      ),
      if (outlineNodeResult.treenode.isConsideredEmpty)
        DeleteOutlineTreenodeRequest(
          outlineTreenodeId: outlineNodeResult.treenode.id,
        ),
    ]);
    return ExecutionInstruction.haltExecution;
  } else {
    if (nodeAfter is TitleNode) {
      editContext.editor.execute([
        ChangeSelectionRequest(
          DocumentSelection.collapsed(
              position: DocumentPosition(
                  nodeId: nodeAfter.id,
                  nodePosition: const TextNodePosition(offset: 0))),
          SelectionChangeType.deleteContent,
          'Backspace pressed',
        ),
        // delete empty paragraph on backspace
        if (textNode.text.toPlainText().isEmpty)
          DeleteNodeRequest(nodeId: textNode.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
  }
  return ExecutionInstruction.continueExecution;
}

ExecutionInstruction enterInOutlineTreeDocument<T extends OutlineTreenode<T>>({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.enter) {
    return ExecutionInstruction.continueExecution;
  }

  if (HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isShiftPressed ||
      HardwareKeyboard.instance.isAltPressed ||
      HardwareKeyboard.instance.isMetaPressed) {
    return ExecutionInstruction.continueExecution;
  }

  final outlineDoc = editContext.document as OutlineEditableDocument;
  // nothing to do if there is no selection
  if (editContext.composer.selection == null) {
    return ExecutionInstruction.continueExecution;
  }
  final selection = editContext.composer.selection!;
  final outlineTreenode =
      outlineDoc.getTreenodeForDocumentNodeId(selection.base.nodeId).treenode;
  // we're not ready with non-text nodes yet
  if (selection.base.nodePosition is! TextNodePosition) {
    return ExecutionInstruction.continueExecution;
  }
  final parent = outlineDoc.root.getParentOf(outlineTreenode.id)!;
  final textNodePosition = selection.base.nodePosition as TextNodePosition;
  final textNode = outlineDoc.getNodeById(selection.base.nodeId) as TextNode;

  if (textNode is TitleNode) {
    if (textNodePosition.offset == 0 && textNode.text.isNotEmpty) {
      // enter pressed at the start of a title node with text in it --
      // prepend a sibling Treenode
      editContext.editor.execute([
        InsertOutlineTreenodeRequest<T>(
          existingTreenodeId: parent.id,
          createChild: true,
          treenodeIndex: parent.children.indexOf(outlineTreenode),
        ),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    if (textNodePosition.offset <= textNode.text.toPlainText().length) {
      // Enter pressed somewhere else in a title node: Jump to start of content,
      // inserting a ParagraphNode if needed
      if (outlineTreenode.contentNodes.isEmpty) {
        final newParagraphNode =
            ParagraphNode(id: uuid.v4(), text: AttributedText(''));
        editContext.editor.execute([
          InsertDocumentNodeInOutlineTreenodeRequest(
            documentNode: newParagraphNode,
            outlineTreenodeId: outlineTreenode.id,
          ),
          ChangeSelectionRequest(
              DocumentSelection.collapsed(
                position: DocumentPosition(
                  nodeId: newParagraphNode.id,
                  nodePosition: const TextNodePosition(offset: 0),
                ),
              ),
              SelectionChangeType.insertContent,
              'jumped to content')
        ]);
      } else {
        editContext.editor.execute([
          ChangeSelectionRequest(
              DocumentSelection.collapsed(
                position: DocumentPosition(
                  nodeId: outlineTreenode.contentNodes.first.id,
                  nodePosition: const TextNodePosition(offset: 0),
                ),
              ),
              SelectionChangeType.insertContent,
              'jumped to content'),
        ]);
      }
      return ExecutionInstruction.haltExecution;
    }

    // now we only have to handle the case of the cursor being at the
    // end when enter is pressed
    // TODO: Hidden-Status berücksichtigen https://github.com/JostSchenck/outline_editor/issues/7
    final newDocNode = ParagraphNode(id: uuid.v4(), text: AttributedText(''));
    editContext.editor.execute([
      InsertDocumentNodeInOutlineTreenodeRequest(
        documentNode: newDocNode,
        outlineTreenodeId: outlineTreenode.id,
        index: 1,
      ),
      ChangeSelectionRequest(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: newDocNode.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
          SelectionChangeType.insertContent,
          'enter pressed')
    ]);
    return ExecutionInstruction.haltExecution;
  }
  return ExecutionInstruction.continueExecution;
}

ExecutionInstruction
    insertTreenodeOnShiftOrCtrlEnter<T extends OutlineTreenode<T>>({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.enter) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) return ExecutionInstruction.continueExecution;
  final outlineDoc = editContext.document as OutlineEditableDocument;

  // prepare splitting a treenode when the cursor is somewhere inbetween in the
  // content nodes
  final curDocNode = outlineDoc.getNodeById(selection.base.nodeId);
  final tnResult =
      outlineDoc.root.getTreenodeContainingDocumentNode(selection.base.nodeId);
  var doSplitTreenode = false;
  if (curDocNode == null || tnResult == null) {
    keyboardActionsLog
        .warning('No valid selection on inserting treenode key combination');
    return ExecutionInstruction.haltExecution;
  }

  if (curDocNode is! TitleNode) {
    if (curDocNode != tnResult.treenode.contentNodes.first &&
        curDocNode != tnResult.treenode.contentNodes.last) {
      // more than two nodes and we're inbetween. So we can tell this treenode
      // has to be split even if this is no TextNode.
      doSplitTreenode = true;
    } else if (curDocNode is TextNode) {
      if (curDocNode == tnResult.treenode.contentNodes.first &&
          (selection.base.nodePosition as TextNodePosition).offset > 0) {
        doSplitTreenode = true;
      } else if (curDocNode == tnResult.treenode.contentNodes.last &&
          (selection.base.nodePosition as TextNodePosition).offset <
              curDocNode.text.length) {
        doSplitTreenode = true;
      }
    }
  }

  if (HardwareKeyboard.instance.isControlPressed) {
    if (selection.isCollapsed) {
      final parentTreenode = outlineDoc
          .getTreenodeForDocumentNodeId(selection.base.nodeId)
          .treenode;

      editContext.editor.execute([
        if (parentTreenode.isCollapsed)
          ChangeCollapsedStateRequest(
              treenodeId: parentTreenode.id, isCollapsed: false),
        InsertOutlineTreenodeRequest<T>(
          existingTreenodeId: parentTreenode.id,
          createChild: true,
          splitAtDocumentPosition: doSplitTreenode ? selection.base : null,
          moveCollapsedSelectionToInsertedNode: true,
          treenodeIndex: 0,
        ),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    if (selection.isCollapsed) {
      editContext.editor.execute([
        InsertOutlineTreenodeRequest<T>(
          existingTreenodeId: outlineDoc
              .getTreenodeForDocumentNodeId(selection.base.nodeId)
              .treenode
              .id,
          createChild: false,
          splitAtDocumentPosition: doSplitTreenode ? selection.base : null,
          // newDocumentNodeId: uuid.v4(),
        ),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }
  return ExecutionInstruction.continueExecution;
}

ExecutionInstruction
    reparentTreenodesOnTabAndShiftTab<T extends OutlineTreenode<T>>({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.tab) {
    return ExecutionInstruction.continueExecution;
  }

  final selection = editContext.composer.selection;
  if (selection == null) return ExecutionInstruction.continueExecution;
  if (!selection.isCollapsed) {
    keyboardActionsLog.warning(
        'Indenting and unindenting non-collapsed selections not yet implemented');
    return ExecutionInstruction.haltExecution;
  }
  final outlineDoc = editContext.document as OutlineEditableDocument<T>;

  // prepare splitting the treenode when the cursor is in the middle of
  // a ParagraphNode
  final treenode = outlineDoc
      .getTreenodeWithPathByDocumentNodeId(selection.base.nodeId)
      .treenode;

  final moveUpInHierarchy = HardwareKeyboard.instance.isShiftPressed;

  editContext.editor.execute([
    ChangeTreenodeIndentationRequest(
      treenodeId: treenode.id,
      moveUpInHierarchy: moveUpInHierarchy,
    ),
  ]);
  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction
    upAndDownBehaviorWithModifiers<T extends OutlineTreenode<T>>({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  if (keyEvent.logicalKey != LogicalKeyboardKey.arrowUp &&
      keyEvent.logicalKey != LogicalKeyboardKey.arrowDown) {
    return ExecutionInstruction.continueExecution;
  }

  final moveUp = keyEvent.logicalKey == LogicalKeyboardKey.arrowUp;
  final selection = editContext.composer.selection;
  if (selection == null) return ExecutionInstruction.continueExecution;
  final outlineDoc = editContext.document as OutlineEditableDocument<T>;

  if (HardwareKeyboard.instance.isAltPressed &&
      HardwareKeyboard.instance.isShiftPressed &&
      !HardwareKeyboard.instance.isControlPressed) {
    if (selection.isCollapsed) {
      final treenodeResult =
          outlineDoc.getTreenodeForDocumentNodeId(selection.base.nodeId);
      final parent = outlineDoc.root.getParentOf(treenodeResult.treenode.id)!;
      final childIndex = parent.children.indexOf(treenodeResult.treenode);
      if (keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
        // swap treenode with sibling before, if we aren't already the first
        // sibling.
        if (childIndex > 0) {
          final newPath = [
            ...treenodeResult.path.sublist(0, treenodeResult.path.length - 1),
            treenodeResult.path.last - 1,
          ];
          editContext.editor.execute([
            MoveOutlineTreenodeRequest(
              treenodeId: treenodeResult.treenode.id,
              newPath: newPath,
            ),
          ]);
        } else {
          keyboardActionsLog.fine("Can't move a sibling further up than pos 0");
          return ExecutionInstruction.haltExecution;
        }
      } else {
        // swap treenode with sibling after, if we aren't already the last
        // sibling.
        if (childIndex < parent.children.length - 1) {
          final newPath = [
            ...treenodeResult.path.sublist(0, treenodeResult.path.length - 1),
            treenodeResult.path.last + 1,
          ];
          editContext.editor.execute([
            MoveOutlineTreenodeRequest(
                treenodeId: treenodeResult.treenode.id, newPath: newPath),
          ]);
        } else {
          keyboardActionsLog.fine("Can't move a sibling further down than end");
          return ExecutionInstruction.haltExecution;
        }
      }
    }
  }

  if (HardwareKeyboard.instance.isControlPressed) {
    if (HardwareKeyboard.instance.isShiftPressed) {
      // Ctrl-Shift-Up and Ctrl-Shift-Down switch siblings up or down, but only
      // direct siblings
      return ExecutionInstruction.continueExecution;
    } else {
      // Ctrl-Up and Ctrl-Down move the caret to the beginning of the treenode
      // before or after base, collapsing it, if it isn't collapsed yet.
      late T newTreenode;
      final curTreenode = outlineDoc
          .getTreenodeWithPathByDocumentNodeId(selection.base.nodeId)
          .treenode;
      final curDocNode = outlineDoc.getNodeById(selection.base.nodeId);
      if (moveUp) {
        if (curDocNode is! TitleNode ||
            (selection.base.nodePosition as TextNodePosition).offset != 0) {
          newTreenode = curTreenode;
        } else {
          newTreenode = outlineDoc.getTreenodeBeforeTreenode(curTreenode.id) ??
              curTreenode;
        }
      } else {
        newTreenode =
            outlineDoc.getTreenodeAfterTreenode(curTreenode.id) ?? curTreenode;
      }
      if (moveUp || newTreenode != curTreenode) {
        editContext.editor.execute([
          ChangeSelectionRequest(
              DocumentSelection.collapsed(
                  position: DocumentPosition(
                      nodeId: newTreenode.titleNode.id,
                      nodePosition: const TextNodePosition(offset: 0))),
              SelectionChangeType.insertContent,
              'jumping outlinetreenode ${moveUp ? 'up' : 'down'}'),
        ]);
      } else {
        // moving downstream, but already in the last treenode, jump to end of it
        editContext.editor.execute([
          ChangeSelectionRequest(
              DocumentSelection.collapsed(position: newTreenode.lastPosition),
              SelectionChangeType.insertContent,
              'jumping outlinetreenode ${moveUp ? 'up' : 'down'}'),
        ]);
      }
      return ExecutionInstruction.haltExecution;
    }
  }
  return ExecutionInstruction.continueExecution;
}

/*
ExecutionInstruction moveUpAndDownWithArrowKeysWithFolding({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }

  const arrowKeys = [
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  ];
  if (!arrowKeys.contains(keyEvent.logicalKey)) {
    return ExecutionInstruction.continueExecution;
  }

  if (CurrentPlatform.isWeb &&
      (editContext.composer.composingRegion.value != null)) {
    // We are composing a character on web. It's possible that a native element is being displayed,
    // like an emoji picker or a character selection panel.
    // We need to let the OS handle the key so the user can navigate
    // on the list of possible characters.
    // TODO: update this after https://github.com/flutter/flutter/issues/134268 is resolved.
    return ExecutionInstruction.blocked;
  }

  if (defaultTargetPlatform == TargetPlatform.windows &&
      HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  if (defaultTargetPlatform == TargetPlatform.linux &&
      HardwareKeyboard.instance.isAltPressed) {
    return ExecutionInstruction.continueExecution;
  }

  bool didMove = false;
  if (keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
    if (CurrentPlatform.isApple && HardwareKeyboard.instance.isAltPressed) {
      didMove = editContext.commonOps.moveCaretUpstream(
        expand: HardwareKeyboard.instance.isShiftPressed,
        movementModifier: MovementModifier.paragraph,
      );
    } else if (CurrentPlatform.isApple &&
        HardwareKeyboard.instance.isMetaPressed) {
      didMove = editContext.commonOps.moveSelectionToBeginningOfDocument(
          expand: HardwareKeyboard.instance.isShiftPressed);
    } else {
      didMove = editContext.commonOps
          .moveCaretUp(expand: HardwareKeyboard.instance.isShiftPressed);
    }
  } else {
    if (CurrentPlatform.isApple && HardwareKeyboard.instance.isAltPressed) {
      didMove = editContext.commonOps.moveCaretDownstream(
        expand: HardwareKeyboard.instance.isShiftPressed,
        movementModifier: MovementModifier.paragraph,
      );
    } else if (CurrentPlatform.isApple &&
        HardwareKeyboard.instance.isMetaPressed) {
      didMove = editContext.commonOps.moveSelectionToEndOfDocument(
          expand: HardwareKeyboard.instance.isShiftPressed);
    } else {
      //didMove = SECommonOps.moveCaretDownWithFolding(expand: HardwareKeyboard.instance.isShiftPressed, editor: editContext.editor);
      didMove = editContext.commonOps
          .moveCaretDown(expand: HardwareKeyboard.instance.isShiftPressed);
    }
  }

  return didMove
      ? ExecutionInstruction.haltExecution
      : ExecutionInstruction.continueExecution;
}
*/
