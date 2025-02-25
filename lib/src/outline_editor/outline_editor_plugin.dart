import 'package:flutter/cupertino.dart';
import 'package:outline_editor/src/commands/move_outline_treenode.dart';
import 'package:outline_editor/src/outline_editor/keyboard_actions.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/components/outline_paragraph_component.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/reactions/outline_selection_reaction.dart';

class OutlineEditorPlugin extends SuperEditorPlugin {
  const OutlineEditorPlugin({
    required this.editor,
    required this.documentLayoutKey,
  });

  final Editor editor;
  final GlobalKey documentLayoutKey;

  @override
  void attach(Editor editor) {
    assert(
        editor.document is OutlineDocument,
        'OutlineEditorPlugin '
        'expects a Document that implements OutlineDocument');
    // editor.reactionPipeline.insert(0, OutlineStructureReaction());
    editor.reactionPipeline.insert(
        0,
        NodeVisibilityReaction(
          editor: editor,
          documentLayoutResolver: () =>
              documentLayoutKey.currentState as DocumentLayout,
        ));
    editor.reactionPipeline.insert(0, OutlineSelectionReaction());
    editor.requestHandlers.addAll(
      <EditRequestHandler>[
        (editor, EditRequest request) => request is ChangeCollapsedStateRequest
            ? ChangeCollapsedStateCommand(
                treenodeId: request.treenodeId,
                isCollapsed: request.isCollapsed,
              )
            : null,
        (editor, request) => request is InsertOutlineTreenodeRequest
            ? InsertOutlineTreenodeCommand(
                existingNode: request.existingTreenode,
                newNode: request.newTreenode,
                createChild: request.createChild,
                treenodeIndex: request.treenodeIndex,
                splitAtDocumentPosition: request.splitAtDocumentPosition,
              )
            : null,
        (editor, request) => request is DeleteOutlineTreenodeRequest
            ? DeleteOutlineTreenodeCommand(
                outlineTreenode: request.outlineTreenode)
            : null,
        (editor, request) => request is MergeOutlineTreenodesRequest
            ? MergeOutlineTreenodesCommand(
                treenodeMergedInto: request.treenodeMergedInto,
                mergedTreenode: request.mergedTreenode,
              )
            : null,
        (editor, request) =>
            request is InsertDocumentNodeInOutlineTreenodeRequest
                ? InsertDocumentNodeInTreenodeContentCommand(
                    documentNode: request.documentNode,
                    outlineTreenode: request.outlineTreenode,
                    index: request.index)
                : null,
        (editor, request) => request is MoveDocumentNodeIntoTreenodeRequest
            ? MoveDocumentNodeIntoTreenodeCommand(
                documentNode: request.documentNode,
                outlineTreenode: request.outlineTreenode,
                index: request.index)
            : null,
        (editor, request) => request is ReparentOutlineTreenodeRequest
            ? ReparentOutlineTreenodeCommand(
                childTreenode: request.childTreenode,
                newParentTreenode: request.newParentTreenode,
                index: request.index)
            : null,
        (editor, request) => request is HideShowContentNodesRequest
            ? HideShowContentNodesCommand(
                treeNodeId: request.treeNodeId,
                hideContent: request.hideContent)
            : null,
        (editor, request) => request is MoveOutlineTreenodeRequest
            ? MoveOutlineTreenodeCommand(
                treenode: request.treenode, path: request.path)
            : null,
        (editor, request) => request is ChangeTreenodeIndentationRequest
            ? ChangeTreenodeIndentationCommand(
                treenode: request.treenode,
                moveUpInHierarchy: request.moveUpInHierarchy)
            : null,
      ],
    );
  }

  @override
  void detach(Editor editor) {
    // editor.reactionPipeline
    //     .removeWhere((element) => element is OutlineStructureReaction);
    editor.reactionPipeline
        .removeWhere((element) => element is NodeVisibilityReaction);

    // TODO: find a way to remove the request handlers. There is no analogon to getters like "componentBuilders"
  }

  @override
  List<ComponentBuilder> get componentBuilders => [
        OutlineTitleComponentBuilder(editor: editor),
        OutlineParagraphComponentBuilder(editor: editor),
      ];

  @override
  List<DocumentKeyboardAction> get keyboardActions => [
        upAndDownBehaviorWithModifiers,
        enterInOutlineTreeDocument,
        deleteSpecialCasesInOutlineTreeDocument,
        backspaceSpecialCasesInOutlineTreeDocument,
        insertTreenodeOnShiftOrCtrlEnter,
        reparentTreenodesOnTabAndShiftTab,
      ];
}
