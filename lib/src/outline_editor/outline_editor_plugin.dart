import 'package:flutter/cupertino.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/move_outline_treenode.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/outline_editor/keyboard_actions.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/reactions/outline_selection_reaction.dart';

class OutlineEditorPlugin extends SuperEditorPlugin {
  const OutlineEditorPlugin({
    required this.editor,
    required this.documentLayoutKey,
    this.defaultTreenodeBuilder = defaultOutlineTreenodeBuilder,
    List<ComponentBuilder>? componentBuilders,
    this.addRequestHandlers = const [],
  }) : _componentBuilders = componentBuilders;

  final Editor editor;
  final GlobalKey documentLayoutKey;
  final TreenodeBuilder defaultTreenodeBuilder;
  final List<ComponentBuilder>? _componentBuilders;
  final List<EditRequestHandler> addRequestHandlers;

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
                existingTreenodeId: request.existingTreenodeId,
                newTreenode: request.newTreenode ?? defaultTreenodeBuilder(),
                createChild: request.createChild,
                treenodeIndex: request.treenodeIndex,
                splitAtDocumentPosition: request.splitAtDocumentPosition,
                // newDocumentNodeId: request.newDocumentNodeId,
                moveCollapsedSelectionToInsertedNode:
                    request.moveCollapsedSelectionToInsertedNode,
                newDocumentNodeId:
                    request.splitAtDocumentPosition != null ? uuid.v4() : null,
              )
            : null,
        (editor, request) => request is DeleteOutlineTreenodeRequest
            ? DeleteOutlineTreenodeCommand(
                outlineTreenodeId: request.outlineTreenodeId)
            : null,
        (editor, request) => request is MergeOutlineTreenodesRequest
            ? MergeOutlineTreenodesCommand(
                treenodeMergedIntoId: request.treenodeMergedIntoId,
                mergedTreenodeId: request.mergedTreenodeId,
              )
            : null,
        (editor, request) =>
            request is InsertDocumentNodeInOutlineTreenodeRequest
                ? InsertDocumentNodeInTreenodeContentCommand(
                    documentNode: request.documentNode,
                    outlineTreenodeId: request.outlineTreenodeId,
                    index: request.index)
                : null,
        (editor, request) => request is MoveDocumentNodeIntoTreenodeRequest
            ? MoveDocumentNodeIntoTreenodeCommand(
                documentNodeId: request.documentNodeId,
                targetTreenodeId: request.targetTreenodeId,
                index: request.index)
            : null,
        (editor, request) => request is ReparentOutlineTreenodeRequest
            ? ReparentOutlineTreenodeCommand(
                childTreenodeId: request.childTreenodeId,
                newParentTreenodeId: request.newParentTreenodeId,
                index: request.index)
            : null,
        (editor, request) => request is HideShowContentNodesRequest
            ? HideShowContentNodesCommand(
                treenodeId: request.treeNodeId,
                hideContent: request.hideContent)
            : null,
        (editor, request) => request is MoveOutlineTreenodeRequest
            ? MoveOutlineTreenodeCommand(
                treenodeId: request.treenodeId, newPath: request.newPath)
            : null,
        (editor, request) => request is ChangeTreenodeIndentationRequest
            ? ChangeTreenodeIndentationCommand(
                treenodeId: request.treenodeId,
                moveUpInHierarchy: request.moveUpInHierarchy)
            : null,
        ...addRequestHandlers,
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
  List<ComponentBuilder> get componentBuilders =>
      _componentBuilders ??
      [
        OutlineTitleComponentBuilder(
          editor: editor,
        ),
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
