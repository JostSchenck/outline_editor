import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/util/logging.dart';

class ChangeCollapsedStateRequest implements EditRequest {
  ChangeCollapsedStateRequest({
    required this.treenodeId,
    required this.isCollapsed,
  });

  final String treenodeId;
  final bool isCollapsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeCollapsedStateRequest &&
          runtimeType == other.runtimeType &&
          treenodeId == other.treenodeId &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode =>
      super.hashCode ^ treenodeId.hashCode ^ isCollapsed.hashCode;
}

class ChangeCollapsedStateCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  ChangeCollapsedStateCommand({
    required this.treenodeId,
    required this.isCollapsed,
  });

  final String treenodeId;
  final bool isCollapsed;

  @override
  // TODO: prüfen: Will ich Ein- und Ausklappen überhaupt undoable?
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing ChangeCollapsedStateCommand, setting $treenodeId to $isCollapsed');
    final outlineDoc = context.document as OutlineEditableDocument<T>;
    final treenode = outlineDoc.getTreenodeById(treenodeId);
    outlineDoc.root = outlineDoc.root.replaceTreenodeById(
      treenodeId,
      (p) => p.copyWith(isCollapsed: isCollapsed),
    );

    executor.logChanges([
      DocumentEdit(
        NodeChangeEvent(treenode.titleNode.id),
      ),
      NodeVisibilityChangeEvent(const NodeVisibilityChange()),
    ]);
  }
}
