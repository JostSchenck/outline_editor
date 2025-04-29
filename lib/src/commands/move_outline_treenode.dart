import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class MoveOutlineTreenodeRequest implements EditRequest {
  MoveOutlineTreenodeRequest({
    required this.treenodeId,
    required this.newPath,
  });

  /// The treenode to be moved.
  final String treenodeId;

  /// The [TreenodePath] to move to.
  final TreenodePath newPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          treenodeId == other.treenodeId &&
          newPath == other.newPath;

  @override
  int get hashCode => super.hashCode ^ treenodeId.hashCode ^ newPath.hashCode;
}

class MoveOutlineTreenodeCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  MoveOutlineTreenodeCommand({
    required this.treenodeId,
    required this.newPath,
  });

  final String treenodeId;
  final TreenodePath newPath;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument<T>;
    commandLog.fine(
      'executing MoveOutlineTreenodeCommand, moving treenode $treenodeId to path $newPath',
    );

    if (treenodeId == outlineDoc.root.id) {
      commandLog
          .severe('MoveOutlineTreenodeCommand called on logical root node');
      return;
    }

    // Suche Treenode und berechne alten Index
    final (treenode: treenode, path: oldPath) =
        outlineDoc.root.getTreenodeAndPathById(treenodeId)!;
    final oldStartIndex = outlineDoc.getNodeIndexById(treenode.nodes.first.id);

    // 1. Entferne Treenode an alter Position
    var newRoot = outlineDoc.root.removeTreenodeAtPath(oldPath);

    // 2. Füge ihn an neuer Position ein
    final targetParentPath = newPath.sublist(0, newPath.length - 1);
    final insertIndex = newPath.last;

    final targetParent = newRoot.getTreenodeByPath(targetParentPath);
    if (targetParent == null) {
      commandLog.severe('Target parent not found for path $targetParentPath');
      return;
    }

    final updatedChildren = List<T>.from(targetParent.children);
    updatedChildren.insert(insertIndex, treenode);

    final updatedParent = targetParent.copyWith(children: updatedChildren);
    newRoot =
        newRoot.replaceTreenodeById(updatedParent.id, (_) => updatedParent);

    // 3. Dokument aktualisieren
    outlineDoc.root = newRoot;

    // 4. Änderungen für History protokollieren
    final newStartIndex = outlineDoc.getNodeIndexById(treenode.nodes.first.id);
    executor.logChanges([
      for (int i = 0; i < treenode.nodesSubtree.length; i++)
        DocumentEdit(
          NodeMovedEvent(
            nodeId: treenode.nodesSubtree[i].id,
            from: oldStartIndex + i,
            to: newStartIndex + i,
          ),
        ),
    ]);
  }

/*
  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument;
    commandLog.fine(
        'executing MoveOutlineTreenodeCommand, moving $treenode to path $path');
    if (treenode == outlineDoc.root) {
      commandLog
          .severe('MoveOutlineTreenodeCommand called on logical root node');
      return;
    }

    final oldStartIndex = outlineDoc.getNodeIndexById(treenode.nodes.first.id);
    treenode.parent!.removeChild(treenode);
    final newParent = path.length == 1
        ? outlineDoc.root
        : outlineDoc.root
            .getOutlineTreenodeByPath(path.sublist(0, path.length - 1));
    newParent!.addChild(treenode, path.last);
    final newStartIndex = outlineDoc.getNodeIndexById(treenode.nodes.first.id);

    executor.logChanges([
      for (int i = 0; i < treenode.nodesSubtree.length; i++)
        DocumentEdit(
          NodeMovedEvent(
            nodeId: treenode.nodesSubtree[i].id,
            from: oldStartIndex + i,
            to: newStartIndex + i,
          ),
        )
    ]);
  }
*/
}
