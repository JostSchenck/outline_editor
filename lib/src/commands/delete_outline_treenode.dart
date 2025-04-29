import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class DeleteOutlineTreenodeRequest implements EditRequest {
  DeleteOutlineTreenodeRequest({
    required this.outlineTreenodeId,
  });

  /// The id of the outline treenode to be deleted
  final String outlineTreenodeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          outlineTreenodeId == other.outlineTreenodeId;

  @override
  int get hashCode => super.hashCode ^ outlineTreenodeId.hashCode;
}

class DeleteOutlineTreenodeCommand extends EditCommand {
  DeleteOutlineTreenodeCommand({
    required this.outlineTreenodeId,
  });

  final String outlineTreenodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog
        .fine('executing DeleteOutlineTreenodeCommand on $outlineTreenodeId');
    final outlineDoc = context.document as OutlineEditableDocument;

    /*// if he OutlineTreenode is not in the document, skip it; this can happen
    // if delete requests for a whole list of OutlineTreenodes is dispatched
    // and a parent of this node already has been deleted.
    if (outlineDoc.root.getOutlineTreenodeById(outlineTreenode.id)==null) {
      commandLog.fine('skipping OutlineTreenode ${outlineTreenode.id}, not found in document. Maybe an ancestor has already been deleted.');
      return;
    }*/

    // if selection is in the OutlineTreenode to be deleted, remove selection;
    // if this is not wanted, it is the responsibility of the caller to move
    // the selection some other place beforehand.
    if (context.composer.selection != null &&
        (outlineDoc
                    .getTreenodeForDocumentNodeId(
                        context.composer.selection!.start.nodeId)
                    .treenode
                    .id ==
                outlineTreenodeId ||
            (outlineDoc
                    .getTreenodeForDocumentNodeId(
                        context.composer.selection!.extent.nodeId)
                    .treenode
                    .id ==
                outlineTreenodeId))) {
      executor.executeCommand(const ChangeSelectionCommand(
          null,
          SelectionChangeType.deleteContent,
          'OutlineTreenode containing selection '));
    }

    final treenode = outlineDoc.root.getTreenodeById(outlineTreenodeId);

    final List<EditEvent> changes = [
      for (int i = 0; i < treenode!.nodesSubtree.length; i++)
        DocumentEdit(
          NodeRemovedEvent(
            treenode.nodesSubtree[i].id,
            treenode.nodesSubtree[i],
          ),
        ),
    ];
    // if this OutlineTreenode has no children, things are trivial, delete it
    if (treenode.children.isEmpty) {
      outlineDoc.root = outlineDoc.root.removeTreenode(treenode.id);
    } else {
      // there are children: move them up in the hierarchy, becoming siblings
      // to the siblings of their former parent; this does not change the order
      // in which they are laid out sequentially.
      commandLog.fine(
          'deleting an OutlineTreenode with children, moving them up in the hierarchy');
      final deletedNodePath = outlineDoc.root.getPathTo(outlineTreenodeId)!;
      final parentPath = deletedNodePath.sublist(0, deletedNodePath.length - 1);
      final deletedNodeIndex = deletedNodePath.last;
      outlineDoc.root = outlineDoc.root.removeTreenode(outlineTreenodeId);
      for (int i = 0; i < treenode.children.length; i++) {
        outlineDoc.root = outlineDoc.root.moveTreenode(
            fromPath: [...deletedNodePath, 0],
            toPath: parentPath,
            insertIndex: deletedNodeIndex + i);
      }
    }
    executor.logChanges(changes);
  }
}
