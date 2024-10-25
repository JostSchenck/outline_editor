import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/delete_outline_treenode.dart';
import 'package:outline_editor/src/commands/move_documentnode_into_treenode.dart';
import 'package:outline_editor/src/commands/reparent_outlinetreenode.dart';
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
        'executing MergeOutlineTreenodesCommand, appending $mergedTreenode to $treenodeMergedInto');
    // if first documentNode is a TitleNode, ditch it, as the TitleNode of the
    // other Treenode wins
    // if (mergedTreenode.headNode is TitleNode) {   ////////////// HEADNODE REFERENZEN AUSBAUEN 22.10.2024 /////////////////////////
    //   executor.executeCommand(
    //       DeleteNodeCommand(nodeId: mergedTreenode.headNode!.id));
    // }

    // append all documentNodes of the merged node one after one to the node merged into
    for (final docNode in [...mergedTreenode.contentNodes]) {
      executor.executeCommand(MoveDocumentNodeIntoTreenodeCommand(
          documentNode: docNode,
          outlineTreenode: treenodeMergedInto,
          index: -1));
    }
    // prepend all children of the merged node one after one to the node merged into
    for (final child in [...mergedTreenode.children.reversed]) {
      executor.executeCommand(ReparentOutlineTreenodeCommand(
          childTreenode: child,
          newParentTreenode: treenodeMergedInto,
          index: 0));
    }
    executor.executeCommand(
        DeleteOutlineTreenodeCommand(outlineTreenode: mergedTreenode));
    // there should not be anything left to log as we only executed other commands.
  }

  final OutlineTreenode treenodeMergedInto;

  final OutlineTreenode mergedTreenode;
}
