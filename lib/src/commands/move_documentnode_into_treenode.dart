import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/insert_documentnode_in_outlinetreenode.dart';
import 'package:outline_editor/src/util/logging.dart';

class MoveDocumentNodeIntoTreenodeRequest implements EditRequest {
  MoveDocumentNodeIntoTreenodeRequest({
    required this.documentNode,
    required this.outlineTreenode,
    this.index = -1,
  });

  final DocumentNode documentNode;
  final OutlineTreenode outlineTreenode;

  /// If -1, will append the DocumentNode, else insert it at index.
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveDocumentNodeIntoTreenodeRequest &&
          runtimeType == other.runtimeType &&
          documentNode == other.documentNode &&
          outlineTreenode == other.outlineTreenode;

  @override
  int get hashCode =>
      super.hashCode ^ documentNode.hashCode ^ outlineTreenode.hashCode;
}

class MoveDocumentNodeIntoTreenodeCommand extends EditCommand {
  MoveDocumentNodeIntoTreenodeCommand({
    required this.documentNode,
    required this.outlineTreenode,
    required this.index,
  });

  final DocumentNode documentNode;
  final OutlineTreenode outlineTreenode;
  final int index;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing MoveDocumentNodeIntoTreenodeCommand, moving $documentNode to OutlineTreenode $outlineTreenode');
    final outlineDoc = context.document as OutlineDocument;
    final oldDocIndex = outlineDoc.getNodeIndexById(documentNode.id);
    executor.executeCommand(DeleteNodeCommand(nodeId: documentNode.id));
    executor.executeCommand(InsertDocumentNodeInOutlineTreenodeCommand(
        documentNode: documentNode,
        outlineTreenode: outlineTreenode,
        index: index == -1 ? outlineTreenode.documentNodes.length : index));
    executor.logChanges([
      DocumentEdit(
        NodeMovedEvent(
          nodeId: documentNode.id,
          from: oldDocIndex,
          to: outlineDoc.getNodeIndexById(documentNode.id),
        ),
      ),
    ]);
  }
}
