import 'package:structured_rich_text_editor/src/util/logging.dart';
import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

class SetChildrenFoldStateRequest implements EditRequest {
  SetChildrenFoldStateRequest({
    required this.treeNodeId,
    required this.fold,
  });

  final String treeNodeId;
  final bool fold;
}

class SetChildrenFoldStateCommand extends EditCommand {
  SetChildrenFoldStateCommand({
    required this.treeNodeId,
    required this.fold,
  });

  /// Id of the [DocumentTreeNode] whose children fold state should be set.
  final String treeNodeId;

  /// Whether the state should be set to folded (true), or unfolded (false).
  final bool fold;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.info('Executing SetChildrenFoldStateCommand');
    commandLog
        .info('   setting tree node folding state for $treeNodeId to $fold');
    context.foldingState.setTreeNodeFoldingState(treeNodeId, fold);
  }
}

class SetDocumentNodesFoldStateRequest implements EditRequest {
  SetDocumentNodesFoldStateRequest({
    required this.documentNodeIds,
    required this.fold,
  });

  final List<String> documentNodeIds;
  final bool fold;
}

class SetDocumentNodesFoldStateCommand extends EditCommand {
  SetDocumentNodesFoldStateCommand({
    required this.documentNodeIds,
    required this.fold,
  });

  /// List of ids of the [DocumentNode]s to fold or unfold.
  final List<String> documentNodeIds;

  /// Whether the state should be set to folded (true), or unfolded (false).
  final bool fold;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.info('Executing SetDocumentNodesFoldStateCommand');
    commandLog.info('   setting folding state for $documentNodeIds to $fold');
    final foldingState = context.foldingState;
    foldingState.setDocumentNodeFoldingState(documentNodeIds, fold);
  }
}
