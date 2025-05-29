import 'package:flutter/cupertino.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/move_outline_treenode.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/outline_editor/keyboard_actions.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/reactions/outline_selection_reaction.dart';

class OutlineEditorPlugin<T extends OutlineTreenode<T>>
    extends SuperEditorPlugin {
  const OutlineEditorPlugin({
    required this.editor,
    required this.documentLayoutKey,
    this.defaultTreenodeBuilder = basicOutlineTreenodeBuilder,
    List<ComponentBuilder>? componentBuilders,
    this.addRequestHandlers = const [],
    this.inlineWidgetBuilders,
    this.hideTextGlobally = false,
  }) : _componentBuilders = componentBuilders;

  final Editor editor;
  final GlobalKey documentLayoutKey;
  final TreenodeBuilder defaultTreenodeBuilder;
  final List<ComponentBuilder>? _componentBuilders;
  final List<EditRequestHandler> addRequestHandlers;
  final InlineWidgetBuilderChain? inlineWidgetBuilders;
  final bool hideTextGlobally;

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
    editor.reactionPipeline.insert(0, OutlineSelectionReaction<T>());
    editor.requestHandlers.addAll(
      <EditRequestHandler>[
        (editor, EditRequest request) => request is ChangeCollapsedStateRequest
            ? ChangeCollapsedStateCommand<T>(
                treenodeId: request.treenodeId,
                isCollapsed: request.isCollapsed,
              )
            : null,
        (editor, request) => request is InsertOutlineTreenodeRequest<T>
            ? InsertOutlineTreenodeCommand<T>(
                existingTreenodeId: request.existingTreenodeId,
                newTreenode:
                    request.newTreenode ?? defaultTreenodeBuilder() as T,
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
            ? DeleteOutlineTreenodeCommand<T>(
                outlineTreenodeId: request.outlineTreenodeId)
            : null,
        (editor, request) => request is MergeOutlineTreenodesRequest
            ? MergeOutlineTreenodesCommand<T>(
                treenodeMergedIntoId: request.treenodeMergedIntoId,
                mergedTreenodeId: request.mergedTreenodeId,
              )
            : null,
        (editor, request) =>
            request is InsertDocumentNodeInOutlineTreenodeRequest
                ? InsertDocumentNodeInTreenodeContentCommand<T>(
                    documentNode: request.documentNode,
                    outlineTreenodeId: request.outlineTreenodeId,
                    index: request.index)
                : null,
        (editor, request) => request is MoveDocumentNodeIntoTreenodeRequest
            ? MoveDocumentNodeIntoTreenodeCommand<T>(
                documentNodeId: request.documentNodeId,
                targetTreenodeId: request.targetTreenodeId,
                index: request.index)
            : null,
        (editor, request) => request is ReparentOutlineTreenodeRequest
            ? ReparentOutlineTreenodeCommand<T>(
                childTreenodeId: request.childTreenodeId,
                newParentTreenodeId: request.newParentTreenodeId,
                index: request.index)
            : null,
        (editor, request) => request is HideShowContentNodesRequest
            ? HideShowContentNodesCommand<T>(
                treenodeId: request.treeNodeId,
                hideContent: request.hideContent)
            : null,
        (editor, request) => request is MoveOutlineTreenodeRequest
            ? MoveOutlineTreenodeCommand<T>(
                treenodeId: request.treenodeId, newPath: request.newPath)
            : null,
        (editor, request) => request is ChangeTreenodeIndentationRequest
            ? ChangeTreenodeIndentationCommand<T>(
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
        OutlineParagraphComponentBuilder(
          editor: editor,
          inlineWidgetBuilders:
              inlineWidgetBuilders ?? defaultInlineWidgetBuilders,
        ),
      ];

  @override
  List<DocumentKeyboardAction> get keyboardActions => [
        upAndDownBehaviorWithModifiers<T>,
        // this keyboard action needs hideTextGlobally passed, so we encapsulate
        // it into a closure
        (
            {required SuperEditorContext editContext,
            required KeyEvent keyEvent}) {
          return enterInOutlineTreeDocument<T>(
            editContext: editContext,
            keyEvent: keyEvent,
            hideTextGlobally: hideTextGlobally,
          );
        },
        deleteSpecialCasesInOutlineTreeDocument<T>,
        backspaceSpecialCasesInOutlineTreeDocument<T>,
        insertTreenodeOnShiftOrCtrlEnter<T>,
        reparentTreenodesOnTabAndShiftTab<T>,
      ];
}
