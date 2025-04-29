import 'package:outline_editor/outline_editor.dart';

class MoveDocumentNodeIntoTreenodeRequest implements EditRequest {
  MoveDocumentNodeIntoTreenodeRequest({
    required this.documentNodeId,
    required this.targetTreenodeId,
    this.index = -1,
  });

  final String documentNodeId;
  final String targetTreenodeId;

  /// If -1, will append the DocumentNode, else insert it at index.
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveDocumentNodeIntoTreenodeRequest &&
          runtimeType == other.runtimeType &&
          documentNodeId == other.documentNodeId &&
          targetTreenodeId == other.targetTreenodeId;

  @override
  int get hashCode =>
      super.hashCode ^ documentNodeId.hashCode ^ targetTreenodeId.hashCode;
}

class MoveDocumentNodeIntoTreenodeCommand extends EditCommand {
  MoveDocumentNodeIntoTreenodeCommand({
    required this.documentNodeId,
    required this.targetTreenodeId,
    required this.index,
  });

  final String documentNodeId;
  final String targetTreenodeId;
  final int index;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument;

    final currentRoot = outlineDoc.root;
    final (treenode: sourceTreenode, path: sourcePath) =
        outlineDoc.root.getTreenodeContainingDocumentNode(documentNodeId) ??
            (throw Exception('Source treenode for $documentNodeId not found'));

    final documentNode = outlineDoc.root.getDocumentNodeById(documentNodeId) ??
        (throw Exception('DocumentNode $documentNodeId not found'));

    final targetTreenode = outlineDoc.root.getTreenodeById(targetTreenodeId) ??
        (throw Exception('Target treenode $targetTreenodeId not found'));

    // 1. Remove from old treenode
    final updatedSourceContent =
        List<DocumentNode>.from(sourceTreenode.contentNodes)
          ..removeWhere((node) => node.id == documentNodeId);
    final updatedSourceTreenode =
        sourceTreenode.copyWith(contentNodes: updatedSourceContent);

    // 2. Insert into new treenode
    final updatedTargetContent =
        List<DocumentNode>.from(targetTreenode.contentNodes);
    if (index >= 0 && index <= updatedTargetContent.length) {
      updatedTargetContent.insert(index, documentNode);
    } else {
      updatedTargetContent.add(documentNode);
    }
    final updatedTargetTreenode =
        targetTreenode.copyWith(contentNodes: updatedTargetContent);

    // 3. Update the root
    var newRoot = currentRoot
        .replaceTreenodeById(
            updatedSourceTreenode.id, (_) => updatedSourceTreenode)
        .replaceTreenodeById(
            updatedTargetTreenode.id, (_) => updatedTargetTreenode);

    outlineDoc.root = newRoot;

    // 4. Log changes
    executor.logChanges([
      DocumentEdit(NodeMovedEvent(
        nodeId: documentNodeId,
        from: outlineDoc.getNodeIndexById(documentNodeId),
        to: outlineDoc.getNodeIndexById(documentNodeId),
      )),
    ]);
  }
}
