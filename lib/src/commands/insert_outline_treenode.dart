import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

import '../infrastructure/uuid.dart';

class InsertOutlineTreenodeRequest implements EditRequest {
  InsertOutlineTreenodeRequest({
    required this.existingTreenode,
    required this.newTreenode,
    required this.createChild,
    this.splitAtDocumentPosition,
    this.treenodeIndex = -1,
  });

  /// The existing node which serves as a reference for the new node, either
  /// as a parent or as a sibling.
  final OutlineTreenode existingTreenode;

  /// The new node to be inserted.
  final OutlineTreenode newTreenode;

  /// true, if the new node should be a child of the existing node, false if it
  /// should be a sibling.
  final bool createChild;

  /// For createChild==true, if -1, the new node will be appended to the list
  /// of children of the existing node. If >=0, the new node will be inserted
  /// at the given index. For createChild==false, if -1, the new node will be
  /// the sibling following existingNode, if >=0, the new node will be
  /// inserted at the given index of existingNode's parent's children.
  final int treenodeIndex;

  /// If this is given, the `existingTreenode` will be split at the given
  /// [DocumentPosition], which must be in the Treenode's *content*. This
  /// will throw if `splitAtDocumentPosition` lies in another treenode or in
  /// an illegal document node (like the title document node).
  final DocumentPosition? splitAtDocumentPosition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          existingTreenode == other.existingTreenode &&
          newTreenode == other.newTreenode &&
          splitAtDocumentPosition == other.splitAtDocumentPosition;

  @override
  int get hashCode =>
      super.hashCode ^
      existingTreenode.hashCode ^
      newTreenode.hashCode ^
      splitAtDocumentPosition.hashCode;
}

class InsertOutlineTreenodeCommand extends EditCommand {
  InsertOutlineTreenodeCommand({
    required this.existingNode,
    required this.newNode,
    required this.createChild,
    required this.treenodeIndex,
    required this.splitAtDocumentPosition,
  });

  final OutlineTreenode existingNode;
  final OutlineTreenode newNode;
  final bool createChild;
  final int treenodeIndex;
  final DocumentPosition? splitAtDocumentPosition;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing InsertOutlineTreenodeCommand, appending $newNode behind $existingNode');
    final outlineDoc = context.document as OutlineDocument;
    if (splitAtDocumentPosition != null) {
      final splitContentNodeIndex = existingNode.contentNodes.indexWhere(
        (e) => e.id == splitAtDocumentPosition!.nodeId,
      );
      if (splitContentNodeIndex == -1) {
        throw Exception("splitAtDocumentPosition lies not in this "
            "OutlineTreenode's content nodes. Might be a TitleNode or a whole "
            "different treenode.");
      }
      if (existingNode.contentNodes[splitContentNodeIndex] is! ParagraphNode) {
        throw Exception("Tried splitting a contentNode element that is "
            "not a ParagraphNode. Only ParagraphNodes can be split at the "
            "moment.");
      }
      executor.executeCommand(SplitParagraphCommand(
        nodeId: splitAtDocumentPosition!.nodeId,
        splitPosition:
            splitAtDocumentPosition!.nodePosition as TextNodePosition,
        newNodeId: uuid.v4(),
        replicateExistingMetadata: true,
      ));
      while(existingNode.contentNodes.length > splitContentNodeIndex+1) {
        newNode.contentNodes.add(existingNode.contentNodes[splitContentNodeIndex+1]);
        existingNode.contentNodes.removeAt(splitContentNodeIndex+1);
      }
    }
    if (createChild) {
      if (treenodeIndex == -1) {
        existingNode.addChild(newNode, 0);
      } else {
        existingNode.addChild(newNode, treenodeIndex);
      }
    } else {
      assert(existingNode.parent != null);
      existingNode.parent!.addChild(
        newNode,
        treenodeIndex == -1 ? existingNode.childIndex + 1 : treenodeIndex,
      );
    }

    final titleNodeIndex = outlineDoc.getNodeIndexById(newNode.titleNode.id);
    executor.logChanges([
      for (int i = 0; i < newNode.nodes.length; i++)
        DocumentEdit(
          NodeInsertedEvent(
            newNode.nodes[i].id,
            titleNodeIndex + i,
          ),
        ),
    ]);
  }
}
