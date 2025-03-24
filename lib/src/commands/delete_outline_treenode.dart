import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class DeleteOutlineTreenodeRequest implements EditRequest {
  DeleteOutlineTreenodeRequest({
    required this.outlineTreenode,
  });

  /// The outline treenode to be deleted
  final OutlineTreenode outlineTreenode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          outlineTreenode == other.outlineTreenode;

  @override
  int get hashCode => super.hashCode ^ outlineTreenode.hashCode;
}

class DeleteOutlineTreenodeCommand extends EditCommand {
  DeleteOutlineTreenodeCommand({
    required this.outlineTreenode,
  });

  final OutlineTreenode outlineTreenode;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog
        .fine('executing DeleteOutlineTreenodeCommand on $outlineTreenode');
    final outlineDoc = context.document as OutlineDocument;

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
        (outlineDoc.getOutlineTreenodeForDocumentNodeId(
                    context.composer.selection!.start.nodeId) ==
                outlineTreenode ||
            (outlineDoc.getOutlineTreenodeForDocumentNodeId(
                    context.composer.selection!.extent.nodeId) ==
                outlineTreenode))) {
      executor.executeCommand(const ChangeSelectionCommand(
          null,
          SelectionChangeType.deleteContent,
          'OutlineTreenode containing selection '));
    }

    final List<EditEvent> changes = [
      for (int i = 0; i < outlineTreenode.nodesSubtree.length; i++)
        DocumentEdit(
          NodeRemovedEvent(
            outlineTreenode.nodesSubtree[i].id,
            outlineTreenode.nodesSubtree[i],
          ),
        ),
    ];
    // if this OutlineTreenode has no children, things are trivial, delete it
    if (outlineTreenode.children.isEmpty) {
      if (outlineTreenode.parent == null) {
        commandLog.severe(
            'Tried deleting the logical root node, this is not allowed');
        return;
      }
      outlineTreenode.parent!.removeChild(outlineTreenode);
    } else {
      // there are children: move them up in the hierarchy, becoming siblings
      // to the siblings of their former parent; this does not change the order
      // in which they are laid out sequentially.
      commandLog.fine(
          'deleting an OutlineTreenode with children, moving them up in the hierarchy');
      final childIndex = outlineTreenode.childIndex;
      for (int i = 0; i < outlineTreenode.children.length; i++) {
        outlineTreenode.parent!
            .addChild(outlineTreenode.children.first, childIndex + i);
      }
    }
    executor.logChanges(changes);
  }
}
