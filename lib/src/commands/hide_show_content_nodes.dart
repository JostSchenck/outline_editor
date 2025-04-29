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

class HideShowContentNodesCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  HideShowContentNodesCommand({
    required this.treenodeId,
    required this.hideContent,
  });

  final String? treenodeId;
  final bool hideContent;

  @override
  // TODO: Will ich das überhaupt in der Undo-History?
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument<T>;
    if (treenodeId == null) {
      outlineDoc.root.traverseUpDown(
          (treenode) => executor.executeCommand(HideShowContentNodesCommand<T>(
                treenodeId: treenode.id,
                hideContent: hideContent,
              )));
      return;
    }
    commandLog.fine(
        'executing HideShowContentNodesCommand, setting $treenodeId to $hideContent');
    final outlineTreenode = outlineDoc.getTreenodeById(treenodeId!);
    if (outlineTreenode.hasContentHidden == hideContent) {
      return;
    }
    outlineDoc.root = outlineDoc.root.replaceTreenodeById(
      treenodeId!,
      (p) => p.copyWith(hasContentHidden: hideContent),
    );
    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(outlineTreenode.titleNode.id),
      ),
      NodeVisibilityChangeEvent(const NodeVisibilityChange()),
    ]);
  }
}
