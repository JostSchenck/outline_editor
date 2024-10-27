import 'package:outline_editor/src/commands/change_collapsed_state.dart';
import 'package:outline_editor/src/commands/delete_outline_treenode.dart';
import 'package:outline_editor/src/commands/hide_show_content_nodes.dart';
import 'package:outline_editor/src/commands/insert_documentnode_in_outlinetreenode.dart';
import 'package:outline_editor/src/commands/insert_outline_treenode.dart';
import 'package:outline_editor/src/commands/merge_outline_treenodes.dart';
import 'package:outline_editor/src/commands/move_documentnode_into_treenode.dart';
import 'package:outline_editor/src/commands/reparent_outlinetreenode.dart';
import 'package:outline_editor/src/outline_editor/keyboard_actions.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/components/outline_paragraph_component.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineEditorPlugin extends SuperEditorPlugin {
  const OutlineEditorPlugin({
    required this.editor,
  });

  final Editor editor;

  @override
  void attach(Editor editor) {
    assert(
        editor.document is OutlineDocument,
        'OutlineEditorPlugin '
        'expects a Document that implements OutlineDocument');
    editor.reactionPipeline.insert(0, OutlineStructureReaction());
    editor.reactionPipeline.insert(0, NodeVisibilityReaction(editor: editor));
    editor.requestHandlers.addAll(
      [
        (request) => request is ChangeCollapsedStateRequest
            ? ChangeCollapsedStateCommand(
                treenodeId: request.treenodeId,
                isCollapsed: request.isCollapsed,
              )
            : null,
        (request) => request is InsertOutlineTreenodeRequest
            ? InsertOutlineTreenodeCommand(
                existingNode: request.existingTreenode,
                newNode: request.newTreenode,
                createChild: request.createChild,
                index: request.index,
              )
            : null,
        (request) => request is DeleteOutlineTreenodeRequest
            ? DeleteOutlineTreenodeCommand(
                outlineTreenode: request.outlineTreenode)
            : null,
        (request) => request is MergeOutlineTreenodesRequest
            ? MergeOutlineTreenodesCommand(
                treenodeMergedInto: request.treenodeMergedInto,
                mergedTreenode: request.mergedTreenode,
              )
            : null,
        (request) => request is InsertDocumentNodeInOutlineTreenodeRequest
            ? InsertDocumentNodeInTreenodeContentCommand(
                documentNode: request.documentNode,
                outlineTreenode: request.outlineTreenode,
                index: request.index)
            : null,
        (request) => request is MoveDocumentNodeIntoTreenodeRequest
            ? MoveDocumentNodeIntoTreenodeCommand(
                documentNode: request.documentNode,
                outlineTreenode: request.outlineTreenode,
                index: request.index)
            : null,
        (request) => request is ReparentOutlineTreenodeRequest
            ? ReparentOutlineTreenodeCommand(
                childTreenode: request.childTreenode,
                newParentTreenode: request.newParentTreenode,
                index: request.index)
            : null,
        (request) => request is HideShowContentNodesRequest
            ? HideShowContentNodesCommand(
                treeNodeId: request.treeNodeId,
                hideContent: request.hideContent)
            : null,
      ],
    );
  }

  @override
  void detach(Editor editor) {
    editor.reactionPipeline
        .removeWhere((element) => element is OutlineStructureReaction);
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
        enterInOutlineTreeDocument,
        deleteEdgeCasesInOutlineTreeDocument,
        backspaceEdgeCasesInOutlineTreeDocument,
        insertTreenodeOnShiftOrCtrlEnter,
      ];
}
