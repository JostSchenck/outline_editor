import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class InsertDocumentNodeInOutlineTreenodeRequest implements EditRequest {
  InsertDocumentNodeInOutlineTreenodeRequest({
    required this.documentNode,
    required this.outlineTreenodeId,
    this.index = -1,
  });

  final DocumentNode documentNode;
  final String outlineTreenodeId;

  /// If -1, will append the DocumentNode, else insert it at index.
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertDocumentNodeInOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          documentNode == other.documentNode &&
          outlineTreenodeId == other.outlineTreenodeId &&
          index == other.index;

  @override
  int get hashCode =>
      super.hashCode ^
      documentNode.hashCode ^
      outlineTreenodeId.hashCode ^
      index.hashCode;
}

class InsertDocumentNodeInTreenodeContentCommand extends EditCommand {
  InsertDocumentNodeInTreenodeContentCommand({
    required this.documentNode,
    required this.outlineTreenodeId,
    required this.index,
  });

  final DocumentNode documentNode;
  final String outlineTreenodeId;
  final int index;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing InsertDocumentNodeInTreenodeContentCommand, inserting $documentNode in $outlineTreenodeId');
    final outlineDoc = context.document as OutlineEditableDocument;
    final targetTreenode = outlineDoc.root.getTreenodeById(outlineTreenodeId);
    if (targetTreenode == null) {
      commandLog.severe('Target treenode $outlineTreenodeId not found');
      return;
    }
    final newContent = List<DocumentNode>.from(targetTreenode.contentNodes);
    if (index >= 0 && index <= newContent.length) {
      newContent.insert(index, documentNode);
    } else {
      newContent.add(documentNode);
    }
    outlineDoc.root = outlineDoc.root.replaceTreenodeById(
      targetTreenode.id,
      (_) => targetTreenode.copyWith(contentNodes: newContent),
    );

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
