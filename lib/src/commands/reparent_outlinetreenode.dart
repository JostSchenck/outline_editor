import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class ReparentOutlineTreenodeRequest implements EditRequest {
  ReparentOutlineTreenodeRequest({
    required this.childTreenodeId,
    required this.newParentTreenodeId,
    this.index = -1,
  });

  final String childTreenodeId;
  final String newParentTreenodeId;

  /// If -1, will append the child, else insert it at index.
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReparentOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          childTreenodeId == other.childTreenodeId &&
          newParentTreenodeId == other.newParentTreenodeId;

  @override
  int get hashCode =>
      super.hashCode ^ childTreenodeId.hashCode ^ newParentTreenodeId.hashCode;
}

class ReparentOutlineTreenodeCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  ReparentOutlineTreenodeCommand({
    required this.childTreenodeId,
    required this.newParentTreenodeId,
    required this.index,
  });

  final String childTreenodeId;
  final String newParentTreenodeId;
  final int index;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument<T>;
    final oldRoot = outlineDoc.root;

    commandLog.fine(
        'executing ReparentOutlineTreenodeCommand, moving $childTreenodeId to $newParentTreenodeId');

    if (childTreenodeId == oldRoot.id) {
      commandLog.severe('tried reparenting root node, this is illegal');
      return;
    }

    final (treenode: childTreenode, path: oldParentPath) =
        oldRoot.getTreenodeAndPathById(childTreenodeId)!;
    final docNodeStartIndexBefore =
        outlineDoc.getNodeIndexById(childTreenode.titleNode.id);

    // 1. Entferne Kind aus altem Parent
    var updatedRoot = oldRoot.removeTreenodeAtPath(oldParentPath);

    // 2. Füge Kind in neuen Parent ein
    final (treenode: newParentTreenode, path: newParentPath) =
        updatedRoot.getTreenodeAndPathById(newParentTreenodeId)!;
    final updatedChildren = List<T>.from(newParentTreenode.children);
    updatedChildren.insert(index, childTreenode);

    final updatedNewParent =
        newParentTreenode.copyWith(children: updatedChildren);
    updatedRoot = updatedRoot.replaceTreenodeById(
        updatedNewParent.id, (_) => updatedNewParent);

    // 3. Setze neuen Root
    outlineDoc.root = updatedRoot;

    // 4. Änderungen für Undo/Redo protokollieren
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
    required this.treenodeId,
    required this.moveUpInHierarchy,
  });

  final String treenodeId;
  final bool moveUpInHierarchy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeTreenodeIndentationRequest &&
          runtimeType == other.runtimeType &&
          treenodeId == other.treenodeId &&
          moveUpInHierarchy == other.moveUpInHierarchy;

  @override
  int get hashCode =>
      super.hashCode ^ treenodeId.hashCode ^ moveUpInHierarchy.hashCode;
}

class ChangeTreenodeIndentationCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  ChangeTreenodeIndentationCommand({
    required this.treenodeId,
    required this.moveUpInHierarchy,
  });

  final String treenodeId;
  final bool moveUpInHierarchy;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument<T>;

    commandLog.fine(
      'executing ChangeTreenodeIndentationCommand, moving $treenodeId ${moveUpInHierarchy ? 'up' : 'down'}',
    );

    final treenode = outlineDoc.root.getTreenodeById(treenodeId);
    if (treenode == null) {
      commandLog.warning('Treenode $treenodeId not found');
      return;
    }
    final parent = outlineDoc.root.getParentOf(treenodeId);
    if (parent == null) {
      commandLog.info('No moving up or down of logical root node');
      return;
    }

    if (moveUpInHierarchy) {
      if (parent == outlineDoc.root) {
        commandLog.info('No moving further up in hierarchy, at top already');
        return;
      }
      final grandParent = outlineDoc.root.getParentOf(parent.id);
      if (grandParent == null) {
        commandLog.warning('Grandparent not found');
        return;
      }
      final childIndex = grandParent.children.indexOf(parent);

      executor.executeCommand(ReparentOutlineTreenodeCommand<T>(
        childTreenodeId: treenodeId,
        newParentTreenodeId: grandParent.id,
        index: childIndex + 1,
      ));
    } else {
      final childIndex = parent.children.indexOf(treenode);
      if (childIndex == 0) {
        commandLog.info('No moving down in hierarchy, no older sibling');
        return;
      }

      final newParent = parent.children[childIndex - 1];
      final selection = context.composer.selection;

      executor.executeCommand(ReparentOutlineTreenodeCommand<T>(
        childTreenodeId: treenodeId,
        newParentTreenodeId: newParent.id,
        index: newParent.children.length,
      ));

      context.composer.setSelectionWithReason(
        selection,
        'reset selection after reparenting',
      );
    }
  }
}
