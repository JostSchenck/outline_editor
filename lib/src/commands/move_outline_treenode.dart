import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class MoveOutlineTreenodeRequest implements EditRequest {
  MoveOutlineTreenodeRequest({
    required this.treenode,
    required this.path,
  });

  /// The treenode to be moved.
  final OutlineTreenode treenode;

  /// The [TreenodePath] to move to.
  final TreenodePath path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MoveOutlineTreenodeRequest &&
              runtimeType == other.runtimeType &&
              treenode == other.treenode &&
              path == other.path;

  @override
  int get hashCode => super.hashCode ^ treenode.hashCode ^ path.hashCode;
}

class MoveOutlineTreenodeCommand extends EditCommand {
  MoveOutlineTreenodeCommand({
    required this.treenode,
    required this.path,
  });

  final OutlineTreenode treenode;
  final TreenodePath path;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing MoveOutlineTreenodeCommand, moving $treenode to path $path');
    if (treenode.parent == null) {
      commandLog
          .severe('MoveOutlineTreenodeCommand called on logical root node');
      return;
    }
    final outlineDoc = context.document as OutlineDocument;

    final oldStartIndex = outlineDoc.getNodeIndexById(treenode.nodes.first.id);
    treenode.parent!.removeChild(treenode);
    final newParent = path.length == 1 ? outlineDoc.root : outlineDoc.root
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
}
