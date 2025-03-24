import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';

import '../util/logging.dart';

class HideShowContentNodesRequest implements EditRequest {
  HideShowContentNodesRequest({
    this.treeNodeId,
    required this.hideContent,
  });

  // if null, hide all content nodes
  final String? treeNodeId;
  final bool hideContent;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HideShowContentNodesRequest &&
        other.treeNodeId == treeNodeId &&
        other.hideContent == hideContent;
  }

  @override
  int get hashCode => treeNodeId.hashCode ^ hideContent.hashCode;
}

class HideShowContentNodesCommand extends EditCommand {
  HideShowContentNodesCommand({
    required this.treeNodeId,
    required this.hideContent,
  });

  final String? treeNodeId;
  final bool hideContent;

  @override
  // TODO: Will ich das überhaupt in der Undo-History?
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineDocument;
    if (treeNodeId == null) {
      outlineDoc.root.traverseUpDown(
          (treenode) => executor.executeCommand(HideShowContentNodesCommand(
                treeNodeId: treenode.id,
                hideContent: hideContent,
              )));
      return;
    }
    commandLog.fine(
        'executing HideShowContentNodesCommand, setting $treeNodeId to $hideContent');
    final outlineTreenode = outlineDoc.getOutlineTreenodeById(treeNodeId!);
    if (outlineTreenode.hasContentHidden == hideContent) {
      return;
    }
    outlineTreenode.hasContentHidden = hideContent;
    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(outlineTreenode.titleNode.id),
      ),
      NodeVisibilityChangeEvent(const NodeVisibilityChange()),
    ]);
  }
}
