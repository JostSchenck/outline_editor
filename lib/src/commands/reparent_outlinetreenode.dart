import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/delete_outline_treenode.dart';
import 'package:outline_editor/src/commands/insert_outline_treenode.dart';
import 'package:outline_editor/src/util/logging.dart';

class ReparentOutlineTreenodeRequest implements EditRequest {
  ReparentOutlineTreenodeRequest({
    required this.childTreenode,
    required this.newParentTreenode,
    this.index = -1,
  });

  final OutlineTreenode childTreenode;
  final OutlineTreenode newParentTreenode;

  /// If -1, will append the child, else insert it at index.
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReparentOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          childTreenode == other.childTreenode &&
          newParentTreenode == other.newParentTreenode;

  @override
  int get hashCode =>
      super.hashCode ^ childTreenode.hashCode ^ newParentTreenode.hashCode;
}

class ReparentOutlineTreenodeCommand extends EditCommand {
  ReparentOutlineTreenodeCommand({
    required this.childTreenode,
    required this.newParentTreenode,
    required this.index,
  });

  final OutlineTreenode childTreenode;
  final OutlineTreenode newParentTreenode;
  final int index;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing ReparentOutlineTreenodeCommand, moving $childTreenode to OutlineTreenode $newParentTreenode');
    if (childTreenode.parent == null) {
      commandLog.severe('tried reparenting root node, this is illegal');
      return;
    }
    executor.executeCommand(
        DeleteOutlineTreenodeCommand(outlineTreenode: childTreenode));
    executor.executeCommand(InsertOutlineTreenodeCommand(
        existingNode: newParentTreenode,
        newNode: childTreenode,
        createChild: true,
        index: index));
  }
}
