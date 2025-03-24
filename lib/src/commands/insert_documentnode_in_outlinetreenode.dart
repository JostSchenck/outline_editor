import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class InsertDocumentNodeInOutlineTreenodeRequest implements EditRequest {
  InsertDocumentNodeInOutlineTreenodeRequest({
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
      other is InsertDocumentNodeInOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          documentNode == other.documentNode &&
          outlineTreenode == other.outlineTreenode &&
          index == other.index;

  @override
  int get hashCode =>
      super.hashCode ^
      documentNode.hashCode ^
      outlineTreenode.hashCode ^
      index.hashCode;
}

class InsertDocumentNodeInTreenodeContentCommand extends EditCommand {
  InsertDocumentNodeInTreenodeContentCommand({
    required this.documentNode,
    required this.outlineTreenode,
    required this.index,
  });

  final DocumentNode documentNode;
  final OutlineTreenode outlineTreenode;
  final int index;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing InsertDocumentNodeInTreenodeContentCommand, inserting $documentNode in $outlineTreenode');
    final outlineDoc = context.document as OutlineDocument;
    outlineTreenode.contentNodes.insert(
        index == -1 ? outlineTreenode.contentNodes.length : index,
        documentNode);
    executor.logChanges([
      DocumentEdit(
        NodeInsertedEvent(
          documentNode.id,
          outlineDoc.getNodeIndexById(documentNode.id),
        ),
      ),
    ]);
  }
}
