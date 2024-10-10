import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/util/logging.dart';

class ChangeCollapsedStateRequest implements EditRequest {
  ChangeCollapsedStateRequest({
    required this.nodeId,
    required this.isCollapsed,
  });

  final String nodeId;
  final bool isCollapsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeCollapsedStateRequest &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode => super.hashCode ^ nodeId.hashCode ^ isCollapsed.hashCode;
}

class ChangeCollapsedStateCommand extends EditCommand {
  ChangeCollapsedStateCommand({
    required this.nodeId,
    required this.isCollapsed,
  });

  final String nodeId;
  final bool isCollapsed;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing ChangeCollapsedStateCommand, setting $nodeId to $isCollapsed');
    final outlineDoc = context.document as OutlineDocument;
    final treenode = outlineDoc.getTreeNodeForDocumentNodeId(nodeId);
    treenode.isCollapsed = isCollapsed;

    executor.logChanges([
      DocumentEdit(
        // we can assume that headNodeId can not be null, because if our nodeId
        // exists, there is at least one documentNodeId.
        NodeChangeEvent(treenode.headNodeId!),
      ),
      DocumentEdit(const NodeVisibilityChange()),
    ]);
  }
}
