import 'dart:math';

import 'package:flutter/services.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/move_outline_treenode.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/reactions/outline_selection_reaction.dart';
import 'package:outline_editor/src/util/logging.dart';
// parts copied from super_editor LICENSE

/// delete treenodes, if the selection spans whole treenodes; if not, return
/// false, so the calling action can decide on passing on or halting.
bool _deleteSelectedTreenodes(OutlineTreeDocument outlineDoc,
    DocumentSelection selection, SuperEditorContext editContext) {
  if (selection.isCollapsed) return false;
  final tn1 =
      outlineDoc.getOutlineTreenodeByDocumentNodeId(selection.base.nodeId);
  final tn2 =
      outlineDoc.getOutlineTreenodeByDocumentNodeId(selection.extent.nodeId);

  if ((selection.base.isEquivalentTo(tn1.firstPosition) &&
          selection.extent.isEquivalentTo(tn2.lastPosition)) ||
      (selection.extent.isEquivalentTo(tn2.firstPosition) &&
          selection.base.isEquivalentTo(tn1.lastPosition))) {
    // whole treenodes are selected; delete a region.
    final flatList = outlineDoc.root.subtreeList;
    int index1 = flatList.indexWhere((treenode) => treenode == tn1);
    int index2 = flatList.indexWhere((treenode) => treenode == tn2);
    final deleteList =
        flatList.sublist(min(index1, index2), max(index1, index2) + 1).reversed;
    final parent = deleteList.last.parent!;
    final childIndex = deleteList.last.childIndex;
    final newEmptyNode = OutlineTreenode(id: uuid.v4(), document: outlineDoc);
    editContext.editor.execute([
      ...deleteList.map((treenode) =>
          DeleteOutlineTreenodeRequest(outlineTreenode: treenode)),
      InsertOutlineTreenodeRequest(
        existingTreenode: parent,
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

ExecutionInstruction backspaceSpecialCasesInOutlineTreeDocument({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  final outlineDoc = editContext.document as OutlineTreeDocument;
  final selection = editContext.composer.selection;

  if (selection == null) return ExecutionInstruction.continueExecution;

  if (!selection.isCollapsed) {
    if (_deleteSelectedTreenodes(outlineDoc, selection, editContext)) {
      return ExecutionInstruction.haltExecution;
    } else {
      return ExecutionInstruction.continueExecution;
    }
  }

  // selection is collapsed
  final outlineNode =
      outlineDoc.getOutlineTreenodeForDocumentNodeId(selection.base.nodeId);
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
    final mergeNodes = outlineNode.isConsideredEmpty ||
        outlineNode.titleNode.text.toPlainText().isEmpty;
    final treenodeBefore = mergeNodes
        ? outlineDoc.getOutlineTreenodeBeforeTreenode(outlineNode)
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
          treenodeMergedInto: treenodeBefore!,
          mergedTreenode: outlineNode,
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

ExecutionInstruction deleteSpecialCasesInOutlineTreeDocument({
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
  final outlineDoc = editContext.document as OutlineTreeDocument;

  if (!selection.isCollapsed) {
    if (_deleteSelectedTreenodes(outlineDoc, selection, editContext)) {
      return ExecutionInstruction.haltExecution;
    } else {
      return ExecutionInstruction.continueExecution;
    }
  }

  final outlineNode =
      outlineDoc.getOutlineTreenodeForDocumentNodeId(selection.base.nodeId);
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
      if (outlineNode.isConsideredEmpty)
        DeleteOutlineTreenodeRequest(
          outlineTreenode: outlineNode,
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

ExecutionInstruction enterInOutlineTreeDocument({
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

  final outlineDoc = editContext.document as OutlineTreeDocument;
  // nothing to do if there is no selection
  if (editContext.composer.selection == null) {
    return ExecutionInstruction.continueExecution;
  }
  final selection = editContext.composer.selection!;
  final outlineTreenode =
      outlineDoc.getOutlineTreenodeForDocumentNodeId(selection.base.nodeId);
  // we're not ready with non-text nodes yet
  if (selection.base.nodePosition is! TextNodePosition) {
    return ExecutionInstruction.continueExecution;
  }
  final textNodePosition = selection.base.nodePosition as TextNodePosition;
  final textNode = outlineDoc.getNodeById(selection.base.nodeId) as TextNode;

  if (textNode is TitleNode) {
    if (textNodePosition.offset == 0) {
      // enter pressed at the start of a title node -- prepend a sibling Treenode
      final newOutlineTreenode = OutlineTreenode(
        id: uuid.v4(),
        document: outlineDoc,
        // contentNodes: [
        //   ParagraphNode(id: uuid.v4(), text: AttributedText('')),
        // ],
      );
      editContext.editor.execute([
        InsertOutlineTreenodeRequest(
          existingTreenode: outlineTreenode.parent!,
          newTreenode: newOutlineTreenode,
          createChild: true,
          treenodeIndex: outlineTreenode.childIndex,
        ),
        ChangeSelectionRequest(
            DocumentSelection.collapsed(
              position: DocumentPosition(
                nodeId: newOutlineTreenode.titleNode.id,
                nodePosition: const TextNodePosition(offset: 0),
              ),
            ),
            SelectionChangeType.insertContent,
            'inserted new treenode'),
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
            outlineTreenode: outlineTreenode,
          ),
          ChangeSelectionRequest(
              DocumentSelection.collapsed(
                position: DocumentPosition(
                  nodeId: newParagraphNode.id,
                  nodePosition: const TextNodePosition(offset: 0),
                ),
              ),
              SelectionChangeType.insertContent,
              'inserted content paragraph'),
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
        outlineTreenode: outlineTreenode,
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

ExecutionInstruction insertTreenodeOnShiftOrCtrlEnter({
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
  final outlineDoc = editContext.document as OutlineTreeDocument;

  // prepare splitting the treenode when the cursor is in the middle of
  // a ParagraphNode
  final curDocNode = outlineDoc.getNodeById(selection.base.nodeId);
  final doSplitParagraph = curDocNode != null &&
      curDocNode is ParagraphNode &&
      (selection.base.nodePosition as TextNodePosition).offset <
          curDocNode.text.length;

  if (HardwareKeyboard.instance.isControlPressed) {
    if (selection.isCollapsed) {
      final parentTreenode =
          outlineDoc.getOutlineTreenodeForDocumentNodeId(selection.base.nodeId);
      final newTreenode = OutlineTreenode(
        id: uuid.v4(),
        document: outlineDoc,
      );

      editContext.editor.execute([
        if (parentTreenode.isCollapsed)
          ChangeCollapsedStateRequest(
              treenodeId: parentTreenode.id, isCollapsed: false),
        InsertOutlineTreenodeRequest(
          existingTreenode: parentTreenode,
          newTreenode: newTreenode,
          createChild: true,
          splitAtDocumentPosition: doSplitParagraph ? selection.base : null,
        ),
        ChangeSelectionRequest(
            DocumentSelection.collapsed(
                position: DocumentPosition(
                    nodeId: newTreenode.titleNode.id,
                    nodePosition: const TextNodePosition(offset: 0))),
            SelectionChangeType.insertContent,
            'outlinetreenode insertion'),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }
  if (HardwareKeyboard.instance.isShiftPressed) {
    if (selection.isCollapsed) {
      final newTreenode = OutlineTreenode(
        id: uuid.v4(),
        document: outlineDoc,
      );
      editContext.editor.execute([
        InsertOutlineTreenodeRequest(
          existingTreenode: outlineDoc
              .getOutlineTreenodeForDocumentNodeId(selection.base.nodeId),
          newTreenode: newTreenode,
          createChild: false,
          splitAtDocumentPosition: doSplitParagraph ? selection.base : null,
        ),
        ChangeSelectionRequest(
            DocumentSelection.collapsed(
                position: DocumentPosition(
                    nodeId: newTreenode.titleNode.id,
                    nodePosition: const TextNodePosition(offset: 0))),
            SelectionChangeType.insertContent,
            'outlinetreenode insertion'),
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }
  return ExecutionInstruction.continueExecution;
}

ExecutionInstruction reparentTreenodesOnTabAndShiftTab({
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
  final outlineDoc = editContext.document as OutlineTreeDocument;

  // prepare splitting the treenode when the cursor is in the middle of
  // a ParagraphNode
  final treenode =
      outlineDoc.getOutlineTreenodeByDocumentNodeId(selection.base.nodeId);

  final moveUpInHierarchy = HardwareKeyboard.instance.isShiftPressed;

  editContext.editor.execute([
    ChangeTreenodeIndentationRequest(
      treenode: treenode,
      moveUpInHierarchy: moveUpInHierarchy,
    ),
  ]);
  return ExecutionInstruction.haltExecution;
}

ExecutionInstruction upAndDownBehaviorWithModifiers({
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
  final outlineDoc = editContext.document as OutlineTreeDocument;

  if (HardwareKeyboard.instance.isAltPressed &&
      HardwareKeyboard.instance.isShiftPressed &&
      !HardwareKeyboard.instance.isControlPressed) {
    if (selection.isCollapsed) {
      final treenode =
          outlineDoc.getOutlineTreenodeForDocumentNodeId(selection.base.nodeId);
      if (keyEvent.logicalKey == LogicalKeyboardKey.arrowUp) {
        // swap treenode with sibling before, if we aren't already the first
        // sibling.
        if (treenode.childIndex > 0) {
          final newPath = [
            ...treenode.path.sublist(0, treenode.path.length - 1),
            treenode.path.last - 1,
          ];
          editContext.editor.execute([
            MoveOutlineTreenodeRequest(treenode: treenode, path: newPath),
          ]);
        } else {
          keyboardActionsLog.fine("Can't move a sibling further up than pos 0");
          return ExecutionInstruction.haltExecution;
        }
      } else {
        // swap treenode with sibling after, if we aren't already the last
        // sibling.
        if (treenode.childIndex < treenode.parent!.children.length - 1) {
          final newPath = [
            ...treenode.path.sublist(0, treenode.path.length - 1),
            treenode.path.last + 1,
          ];
          editContext.editor.execute([
            MoveOutlineTreenodeRequest(treenode: treenode, path: newPath),
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
      late OutlineTreenode newTreenode;
      final curTreenode =
          outlineDoc.getOutlineTreenodeByDocumentNodeId(selection.base.nodeId);
      final curDocNode = outlineDoc.getNodeById(selection.base.nodeId);
      if (moveUp) {
        if (curDocNode is! TitleNode ||
            (selection.base.nodePosition as TextNodePosition).offset != 0) {
          newTreenode = curTreenode;
        } else {
          newTreenode =
              outlineDoc.getOutlineTreenodeBeforeTreenode(curTreenode) ??
                  curTreenode;
        }
      } else {
        // FIXME: Move to end of node, if we are already somewhere in last
        newTreenode = outlineDoc.getOutlineTreenodeAfterTreenode(curTreenode) ??
            curTreenode;
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
