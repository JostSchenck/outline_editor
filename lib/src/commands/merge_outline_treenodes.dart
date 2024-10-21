import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/delete_outline_treenode.dart';
import 'package:outline_editor/src/commands/move_documentnode_into_treenode.dart';
import 'package:outline_editor/src/util/logging.dart';

class MergeOutlineTreenodesRequest implements EditRequest {
  MergeOutlineTreenodesRequest({
    required this.treenodeMergedInto,
    required this.mergedTreenode,
  });

  final OutlineTreenode treenodeMergedInto;
  final OutlineTreenode mergedTreenode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MergeOutlineTreenodesRequest &&
              runtimeType == other.runtimeType &&
              treenodeMergedInto == other.treenodeMergedInto &&
              mergedTreenode == other.mergedTreenode;

  @override
  int get hashCode =>
      super.hashCode ^ treenodeMergedInto.hashCode ^ mergedTreenode.hashCode;
}

class MergeOutlineTreenodesCommand extends EditCommand {
  MergeOutlineTreenodesCommand({
    required this.treenodeMergedInto,
    required this.mergedTreenode,
  });

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing InsertOutlineTreenodeCommand, appending $mergedTreenode to $treenodeMergedInto');
    if (mergedTreenode.documentNodes.isEmpty) {
      // nothing to do except removing this contentless treenode
      executor.executeCommand(
          DeleteOutlineTreenodeCommand(outlineTreenode: mergedTreenode));
      return;
    }
    // if first documentNode is a TitleNode, ditch it
    if (mergedTreenode.headNode is TitleNode) {
      executor.executeCommand(DeleteNodeCommand(nodeId: mergedTreenode.headNode!.id));
    }
    // append all documentNodes of the merged node one after one to the node merged into
    for (final docNode in mergedTreenode) {
      executor.executeCommand(MoveDocumentNodeIntoTreenodeCommand(
          documentNode: docNode,
          outlineTreenode: treenodeMergedInto,
          index: -1));
    }
    executor.executeCommand(
        DeleteOutlineTreenodeCommand(outlineTreenode: mergedTreenode));
    // there should not be anything left to log as we only executed other commands.
  }

  final OutlineTreenode treenodeMergedInto;

  final OutlineTreenode mergedTreenode;
}
