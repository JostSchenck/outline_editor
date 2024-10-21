import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/insert_outline_treenode.dart';
import 'package:outline_editor/src/commands/merge_outline_treenodes.dart';
import 'package:outline_editor/src/infrastructure/platform.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
// parts copied from super_editor LICENSE

ExecutionInstruction backspaceEdgeCasesInOutlineTreeDocument({
  required SuperEditorContext editContext,
  required KeyEvent keyEvent,
}) {
  if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
    return ExecutionInstruction.continueExecution;
  }

  // we only care about collapsed selections
  final selection = editContext.composer.selection;
  if (selection == null) return ExecutionInstruction.continueExecution;
  if (!selection.isCollapsed) return ExecutionInstruction.continueExecution;

  // we only care, if the cursor is at the start of a text node
  final outlineDoc = editContext.document as OutlineTreeDocument;
  final outlineNode =
  outlineDoc.getOutlineTreenodeForDocumentNodeId(selection.start.nodeId);
  if (selection.start.nodePosition is! TextNodePosition) {
    return ExecutionInstruction.continueExecution;
  }
  final textNodePosition = selection.start.nodePosition as TextNodePosition;
  if (textNodePosition.offset != 0) {
    return ExecutionInstruction.continueExecution;
  }
  final textNode = outlineDoc.getNodeById(selection.start.nodeId)!;

  if (textNode is TitleNode) {
    // if at the beginning of a non-empty title node, just move caret to the end of the
    // preceding node. If the title node is empty, merge treenodes.
    final nodeBefore = outlineDoc.getNodeBefore(textNode);
    if (nodeBefore == null || nodeBefore is! TextNode) {
      return ExecutionInstruction.haltExecution;
    }
    final mergeNodes = outlineNode.isConsideredEmpty ||
        outlineNode.headNode is TitleNode &&
            (outlineNode.headNode as TitleNode).text.text.isEmpty;
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
              nodePosition: TextNodePosition(
                  offset: nodeBefore.text.text.length),
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
                  nodePosition:
                  TextNodePosition(offset: nodeBefore.text.text.length))),
          SelectionChangeType.deleteContent,
          'Backspace pressed',
        ),
        // delete empty paragraph on backspace
        if ((textNode as TextNode).text.text.isEmpty)
          DeleteNodeRequest(nodeId: textNode.id),
      ]);
      return ExecutionInstruction.haltExecution;
    }
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

  if (HardwareKeyboard.instance.isControlPressed) {
    if (selection.isCollapsed) {
      final newTreenode = OutlineTreenode(
        id: uuid.v4(),
        document: outlineDoc,
        documentNodes: [
          TitleNode(
              id: uuid.v4(), text: AttributedText('New OutlineTreenode')),
          ParagraphNode(id: uuid.v4(), text: AttributedText('')),
        ],
      );
      editContext.editor.execute([
        InsertOutlineTreenodeRequest(
          existingTreenode: outlineDoc
              .getOutlineTreenodeForDocumentNodeId(selection.base.nodeId),
          newTreenode: newTreenode,
          createChild: true,
        ),
        ChangeSelectionRequest(
            DocumentSelection.collapsed(
                position: DocumentPosition(
                    nodeId: newTreenode.first.id, // FIXME: make this TitleNode, when those are separated
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
      editContext.editor.execute([
        InsertOutlineTreenodeRequest(
          existingTreenode: outlineDoc
              .getOutlineTreenodeForDocumentNodeId(selection.base.nodeId),
          newTreenode: OutlineTreenode(
            id: uuid.v4(),
            document: outlineDoc,
            documentNodes: [
              TitleNode(
                  id: uuid.v4(), text: AttributedText('New OutlineTreenode')),
              ParagraphNode(id: uuid.v4(), text: AttributedText('')),
            ],
          ),
          createChild: false,
        )
      ]);
      return ExecutionInstruction.haltExecution;
    }
    return ExecutionInstruction.continueExecution;
  }
  return ExecutionInstruction.continueExecution;
}

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
