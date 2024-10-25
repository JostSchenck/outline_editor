/// This command is used as a replacement for super_editor's DeleteContentCommand
/// when receiving a DeleteContentRequest, as deleting ranges in an outline
/// needs taking care of the structure.
///
/// TODO: Maybe not needed if we take care of always correcting the selection
/// to a legal state.
///
/*
class OutlineDeleteContentCommand extends EditCommand {
  OutlineDeleteContentCommand({
    required this.documentRange,
  });

  final DocumentRange documentRange;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  String describe() => "Delete content within range: $documentRange";

  @override
  void execute(EditContext context, CommandExecutor executor) {

  }
}
*/
