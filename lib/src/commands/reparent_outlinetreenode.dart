import 'package:outline_editor/outline_editor.dart';
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
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing ReparentOutlineTreenodeCommand, moving $childTreenode to OutlineTreenode $newParentTreenode');
    if (childTreenode.parent == null) {
      commandLog.severe('tried reparenting root node, this is illegal');
      return;
    }
    final outlineDoc = context.document as OutlineDocument;
    final docNodeStartIndexBefore =
        outlineDoc.getNodeIndexById(childTreenode.titleNode.id);

    childTreenode.parent!.removeChild(childTreenode);
    newParentTreenode.addChild(childTreenode, index);
    final docNodeStartIndexAfter =
        outlineDoc.getNodeIndexById(childTreenode.titleNode.id);

    final movedNodes = childTreenode.nodesSubtree;
    executor.logChanges([
      for (int i = 0; i < movedNodes.length; i++)
        DocumentEdit(NodeMovedEvent(
          nodeId: movedNodes[i].id,
          from: docNodeStartIndexBefore + i,
          to: docNodeStartIndexAfter + i,
        )),
    ]);
  }
}

class ChangeTreenodeIndentationRequest implements EditRequest {
  ChangeTreenodeIndentationRequest({
    required this.treenode,
    required this.moveUpInHierarchy,
  });

  final OutlineTreenode treenode;
  final bool moveUpInHierarchy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeTreenodeIndentationRequest &&
          runtimeType == other.runtimeType &&
          treenode == other.treenode &&
          moveUpInHierarchy == other.moveUpInHierarchy;

  @override
  int get hashCode =>
      super.hashCode ^ treenode.hashCode ^ moveUpInHierarchy.hashCode;
}

class ChangeTreenodeIndentationCommand extends EditCommand {
  ChangeTreenodeIndentationCommand({
    required this.treenode,
    required this.moveUpInHierarchy,
  });

  final OutlineTreenode treenode;
  final bool moveUpInHierarchy;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing ChangeTreenodeIndentationCommand, moving $treenode ${moveUpInHierarchy ? 'up' : 'down'}');

    if (moveUpInHierarchy) {
      final parent = treenode.parent;
      if (parent == null || parent.parent == null) {
        commandLog.info('No moving further up in hierarchy, up there already');
        return;
      }
      // final selection = context.composer.selection;
      executor.executeCommand(ReparentOutlineTreenodeCommand(
        childTreenode: treenode,
        newParentTreenode: parent.parent!,
        index: parent.childIndex + 1,
      ));
      // context.composer.setSelectionWithReason(selection, 'reset selection after reparenting');
    } else {
      if (treenode.parent == null) {
        commandLog.info(
            'No moving down in hierarchy, no older sibling for root node');
        return;
      }
      if (treenode.childIndex == 0) {
        commandLog.info('No moving down in hierarchy, no older sibling');
        return;
      }
      final newParent = treenode.parent!.children[treenode.childIndex - 1];
      final selection = context.composer.selection;
      executor.executeCommand(ReparentOutlineTreenodeCommand(
        childTreenode: treenode,
        newParentTreenode: newParent,
        index: newParent.children.length,
      ));
      context.composer.setSelectionWithReason(
          selection, 'reset selection after reparenting');
    }
  }
}
