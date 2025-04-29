import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class MergeOutlineTreenodesRequest implements EditRequest {
  MergeOutlineTreenodesRequest({
    required this.treenodeMergedIntoId,
    required this.mergedTreenodeId,
  });

  final String treenodeMergedIntoId;
  final String mergedTreenodeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MergeOutlineTreenodesRequest &&
          runtimeType == other.runtimeType &&
          treenodeMergedIntoId == other.treenodeMergedIntoId &&
          mergedTreenodeId == other.mergedTreenodeId;

  @override
  int get hashCode =>
      super.hashCode ^
      treenodeMergedIntoId.hashCode ^
      mergedTreenodeId.hashCode;
}

class MergeOutlineTreenodesCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  MergeOutlineTreenodesCommand({
    required this.treenodeMergedIntoId,
    required this.mergedTreenodeId,
  });

  final String treenodeMergedIntoId;
  final String mergedTreenodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing MergeOutlineTreenodesCommand, appending $mergedTreenodeId to $treenodeMergedIntoId');
    final outlineDoc = context.document as OutlineEditableDocument<T>;
    final treenodeMergedInto =
        outlineDoc.root.getTreenodeById(treenodeMergedIntoId) ??
            (throw Exception(
                'Treenode to merge into $treenodeMergedIntoId not found'));
    final mergedTreenode = outlineDoc.root.getTreenodeById(mergedTreenodeId) ??
        (throw Exception('Treenode to merge $mergedTreenodeId not found'));

    // append all documentNodes of the merged node one after one to the node merged into
    for (final docNode in [...mergedTreenode.contentNodes]) {
      executor.executeCommand(MoveDocumentNodeIntoTreenodeCommand<T>(
          documentNodeId: docNode.id,
          targetTreenodeId: treenodeMergedInto.id,
          index: -1));
    }
    // prepend all children of the merged node one after one to the node merged into
    for (final child in [...mergedTreenode.children.reversed]) {
      executor.executeCommand(ReparentOutlineTreenodeCommand<T>(
          childTreenodeId: child.id,
          newParentTreenodeId: treenodeMergedIntoId,
          index: 0));
    }
    executor.executeCommand(
        DeleteOutlineTreenodeCommand<T>(outlineTreenodeId: mergedTreenodeId));
    // there should not be anything left to log as we only executed other commands.
  }
}
