import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/util/logging.dart';

class InsertOutlineTreenodeRequest implements EditRequest {
  InsertOutlineTreenodeRequest({
    required this.existingNode,
    required this.newNode,
    required this.createChild,
    this.index = -1,
  });

  /// The existing node which serves as a reference for the new node, either
  /// as a parent or as a sibling.
  final OutlineTreenode existingNode;

  /// The new node to be inserted.
  final OutlineTreenode newNode;

  /// true, if the new node should be a child of the existing node, false if it
  /// should be a sibling.
  final bool createChild;

  /// For createChild==true, if -1, the new node will be appended to the list
  /// of children of the existing node. If >=0, the new node will be inserted
  /// at the given index. For createChild==true, if -1, the new node will be
  /// the sibling following existingNode, if >=0, the new node will be
  /// inserted at the given index of existingNode's parent's children.
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          existingNode == other.existingNode &&
          newNode == other.newNode;

  @override
  int get hashCode => super.hashCode ^ existingNode.hashCode ^ newNode.hashCode;
}

class InsertOutlineTreenodeCommand extends EditCommand {
  InsertOutlineTreenodeCommand({
    required this.existingNode,
    required this.newNode,
    required this.createChild,
    required this.index,
  });

  final OutlineTreenode existingNode;
  final OutlineTreenode newNode;
  final bool createChild;
  final int index;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing InsertOutlineTreenodeCommand, appending $newNode to $existingNode');
    final outlineDoc = context.document as OutlineDocument;
    if (createChild) {
      if (index == -1) {
        existingNode.addChild(newNode);
      } else {
        existingNode.children.insert(index, newNode);
      }
    } else {
      assert(existingNode.parent != null);
      existingNode.parent!.addChild(
        newNode,
        index,
      );
    }

    final firstDocNode = newNode.firstDocumentNodeInSubtree;
    if (firstDocNode == null) {
      return;
    }
    final firstDocNodeIndex = outlineDoc.getNodeIndexById(firstDocNode.id);
    executor.logChanges([
      for (int i = 0; i < newNode.documentNodes.length; i++)
        DocumentEdit(
          NodeInsertedEvent(
            newNode.documentNodes[i].id,
            firstDocNodeIndex + i,
          ),
        ),
    ]);
    executor.executeCommand(ChangeSelectionCommand(
        DocumentSelection.collapsed(
            position: DocumentPosition(
                nodeId: firstDocNode.id,
                nodePosition: const TextNodePosition(offset: 0))),
        SelectionChangeType.insertContent,
        'outlinetreenode insertion'));
  }
}
