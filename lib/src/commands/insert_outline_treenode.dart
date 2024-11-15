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

    final changes = <DocumentEdit>[];

    // First add the given new OutlineTreenode at the right position
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

    // Start collecting the document edits we have to log later. Start with
    // the nodes in our new outlinetreenode, which we count as newly inserted
    // nodes.
    final newTitleNodeIndex = outlineDoc.getNodeIndexById(newNode.titleNode.id);
    changes.addAll([
      for (int i = 0; i < newNode.nodes.length; i++)
        DocumentEdit(
          NodeInsertedEvent(
            newNode.nodes[i].id,
            newTitleNodeIndex + i,
          ),
        )
    ]);

    // Now see if we have to split our existing node, which would mean
    // moving some nodes between our two OutlineTreenodes, possibly creating
    // one new DocumentNode, if a Paragraph is split somewhere in the middle.
    // Splitting only is allowed in an OutlineTreenode's *contentNodes*, not
    // in a title node. If the split occurs somewhere in the middle of a
    // DocumentNode, this currently is only allowed for a ParagraphNode.
    if (splitAtDocumentPosition != null) {
      // the index of the node where the split happens in the list of
      // contentNodes
      final splitContentNodeIndex = existingNode.contentNodes.indexWhere(
            (e) => e.id == splitAtDocumentPosition!.nodeId,
      );
      // index of the first contentNode that will be moved to the new treenode.
      // This may change if we have to split a ParagraphNode.
      var splitStartIndex = splitContentNodeIndex;
      final splitContentNode = existingNode.contentNodes[splitContentNodeIndex];

      if (splitContentNodeIndex == -1) {
        throw Exception("splitAtDocumentPosition lies not in this "
            "OutlineTreenode's content nodes. Might be a TitleNode or a whole "
            "different treenode.");
      }
      if (splitAtDocumentPosition!.nodePosition is TextNodePosition &&
          (splitAtDocumentPosition!.nodePosition as TextNodePosition).offset >
              0 &&
          (splitAtDocumentPosition!.nodePosition as TextNodePosition).offset <
              (splitContentNode as TextNode).text.length) {
        // We have to split a node in the middle; this can right now only
        // be done in a ParagraphNode.
        if (existingNode.contentNodes[splitContentNodeIndex]
        is! ParagraphNode) {
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
        splitStartIndex++;
      }
      // Now move the latter part of the contentNodes to the new treenode
      final existingTitleNodeIndex = outlineDoc.getNodeIndexById(
          existingNode.titleNode.id);
      while (existingNode.contentNodes.length > splitStartIndex) {
        final nodeId = existingNode.contentNodes[splitStartIndex].id;
        newNode.contentNodes
            .add(existingNode.contentNodes[splitStartIndex]);
        existingNode.contentNodes.removeAt(splitStartIndex);
        changes.add(DocumentEdit(NodeMovedEvent(
          from: existingTitleNodeIndex + splitStartIndex + 1,
          to: newTitleNodeIndex + 1 + newNode.contentNodes.length,
          nodeId: nodeId,
        )));
      }
    }

    executor.logChanges(changes);
  }
}
