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
  void execute(EditContext context, CommandExecutor executor) {
    commandLog
        .fine('executing DeleteOutlineTreenodeCommand on $outlineTreenode');
    final outlineDoc = context.document as OutlineDocument;

    // if selection is in the OutlineTreenode to be deleted, remove selection;
    // if this is not wanted, it is the responsibility of the caller to move
    // the selection some other place beforehand.
    if (context.composer.selection != null &&
            outlineDoc.getOutlineTreenodeForDocumentNodeId(
                    context.composer.selection!.start.nodeId) ==
                outlineTreenode ||
        (outlineDoc.getOutlineTreenodeForDocumentNodeId(
                    context.composer.selection!.extent.nodeId) ==
                outlineTreenode)) {
      executor.executeCommand(const ChangeSelectionCommand(
          null,
          SelectionChangeType.deleteContent,
          'OutlineTreenode containing selection '));
    }

    // if this OutlineTreenode has no children, things are trivial, delete it
    if (outlineTreenode.children.isEmpty) {
      if (outlineTreenode.parent == null) {
        commandLog.severe(
            'Tried deleting the logical root node, this is not allowed');
        return;
      }
      outlineTreenode.parent!.removeChild(outlineTreenode);
    } else {
      // there are children: How do we treat this? For now: stop. TODO
      return;
    }
    executor.logChanges([
      for (int i = 0; i < outlineTreenode.nodes.length; i++)
        DocumentEdit(
          NodeRemovedEvent(
            outlineTreenode.nodes[i].id,
            outlineTreenode.nodes[i],
          ),
        ),
    ]);
  }
}
