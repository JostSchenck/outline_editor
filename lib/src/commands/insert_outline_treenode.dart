import 'package:outline_editor/src/util/logging.dart';
import 'package:super_editor/super_editor.dart';

import '../outline_document/outline_editable_document.dart';
import '../outline_document/outline_treenode.dart';

class InsertOutlineTreenodeRequest<T extends OutlineTreenode<T>>
    implements EditRequest {
  InsertOutlineTreenodeRequest({
    required this.existingTreenodeId,
    this.newTreenode,
    required this.createChild,
    this.splitAtDocumentPosition,
    this.treenodeIndex = -1,
    this.moveCollapsedSelectionToInsertedNode = true,
  });

  /// ID of the existing node which serves as a reference for the new node,
  /// either as a parent or as a sibling.
  final String existingTreenodeId;

  /// The new node to be inserted.
  final T? newTreenode;

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

  /// Node id to be used if `splitAtDocumentPosition` is true. As
  /// for undo-History every command must be completely deterministic, this
  /// means the command must not generate a new node id, so the a potential
  /// node id must be created by the caller.
  // final String? newDocumentNodeId;

  /// Whether after insertion the caret should be moved to position 0 of the
  /// newly inserted Treenode.
  final bool moveCollapsedSelectionToInsertedNode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsertOutlineTreenodeRequest &&
          runtimeType == other.runtimeType &&
          existingTreenodeId == other.existingTreenodeId &&
          newTreenode == other.newTreenode &&
          splitAtDocumentPosition == other.splitAtDocumentPosition;

  @override
  int get hashCode =>
      super.hashCode ^
      existingTreenodeId.hashCode ^
      newTreenode.hashCode ^
      splitAtDocumentPosition.hashCode;
}

class InsertOutlineTreenodeCommand<T extends OutlineTreenode<T>>
    extends EditCommand {
  InsertOutlineTreenodeCommand({
    required this.existingTreenodeId,
    required this.newTreenode,
    required this.createChild,
    required this.treenodeIndex,
    required this.splitAtDocumentPosition,
    required this.moveCollapsedSelectionToInsertedNode,
    required this.newDocumentNodeId,
  });

  final String existingTreenodeId;
  final T newTreenode;
  final bool createChild;
  final int treenodeIndex;
  final DocumentPosition? splitAtDocumentPosition;
  final bool moveCollapsedSelectionToInsertedNode;
  final String? newDocumentNodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final outlineDoc = context.document as OutlineEditableDocument<T>;
    final existingTreenode =
        outlineDoc.root.getTreenodeById(existingTreenodeId);

    if (existingTreenode == null) {
      commandLog.severe('Existing treenode $existingTreenodeId not found');
      return;
    }

    final changes = <DocumentEdit>[];

    T updatedRoot = outlineDoc.root;

    // --- 1. Einfügen des neuen Treenodes ---
    if (createChild) {
      final updatedParent = existingTreenode.copyInsertChild(
        child: newTreenode,
        atIndex: treenodeIndex == -1
            ? existingTreenode.children.length
            : treenodeIndex,
      );
      updatedRoot = updatedRoot.replaceTreenodeById(
          existingTreenodeId, (_) => updatedParent);
    } else {
      if (existingTreenodeId == updatedRoot.id) {
        commandLog.severe('Cannot insert sibling for root node');
        return;
      }
      final parent = updatedRoot.getParentOf(existingTreenodeId);
      if (parent == null) {
        commandLog.severe('Parent not found for treenode $existingTreenodeId');
        return;
      }

      final parentUpdated = parent.copyInsertChild(
        child: newTreenode,
        atIndex: treenodeIndex == -1
            ? updatedRoot.getPathTo(existingTreenodeId)!.last + 1
            : treenodeIndex,
      );
      updatedRoot =
          updatedRoot.replaceTreenodeById(parent.id, (_) => parentUpdated);
    }
    outlineDoc.root = updatedRoot;
    final newTitleNodeIndex =
        outlineDoc.getNodeIndexById(newTreenode.titleNode.id);

    changes.addAll([
      for (int i = 0;
          i <
              newTreenode.subtreeList
                  .expand((t) => [t.titleNode, ...t.contentNodes])
                  .length;
          i++)
        DocumentEdit(
          NodeInsertedEvent(
            newTreenode.subtreeList
                .expand((t) => [t.titleNode, ...t.contentNodes])
                .toList()[i]
                .id,
            newTitleNodeIndex + i,
          ),
        )
    ]);

    // --- 2. Optionales Splitten ---
    if (splitAtDocumentPosition != null) {
      final splitContentNodeIndex = existingTreenode.contentNodes.indexWhere(
        (e) => e.id == splitAtDocumentPosition!.nodeId,
      );
      if (splitContentNodeIndex == -1) {
        throw Exception(
            'splitAtDocumentPosition does not lie inside existingTreenode content.');
      }

      final splitContentNode =
          existingTreenode.contentNodes[splitContentNodeIndex];

      bool needSplit = false;
      if (splitAtDocumentPosition!.nodePosition is TextNodePosition) {
        final offset =
            (splitAtDocumentPosition!.nodePosition as TextNodePosition).offset;
        if (offset > 0 && offset < (splitContentNode as TextNode).text.length) {
          needSplit = true;
        }
      }

      if (needSplit) {
        // Split ParagraphNode
        executor.executeCommand(SplitParagraphCommand(
          nodeId: splitAtDocumentPosition!.nodeId,
          splitPosition:
              splitAtDocumentPosition!.nodePosition as TextNodePosition,
          newNodeId: newDocumentNodeId!,
          replicateExistingMetadata: true,
        ));
        // muss hier nicht noch newDocumentNodeId dem Treenode zugeordnet
        // werden? Oder passiert das automatisch über OutlineEditableDocument.insertNodeAt?
      }

      final changedExistingTreenode =
          outlineDoc.root.getTreenodeById(existingTreenodeId)!;
      final remainingContent = changedExistingTreenode.contentNodes
          .sublist(0, splitContentNodeIndex + 1);
      final movedContent = changedExistingTreenode.contentNodes
          .sublist(splitContentNodeIndex + 1);

      final updatedExisting =
          changedExistingTreenode.copyWith(contentNodes: remainingContent);
      final updatedNew = newTreenode.copyWith(contentNodes: [
        ...movedContent,
        ...newTreenode.contentNodes,
      ]);

      outlineDoc.root = outlineDoc.root
          .replaceTreenodeById(existingTreenode.id, (_) => updatedExisting)
          .replaceTreenodeById(newTreenode.id, (_) => updatedNew);

      final existingTitleNodeIndex =
          outlineDoc.getNodeIndexById(existingTreenode.titleNode.id);

      for (final node in movedContent) {
        changes.add(
          DocumentEdit(
            NodeMovedEvent(
              nodeId: node.id,
              from: existingTitleNodeIndex + 1,
              to: newTitleNodeIndex +
                  1 +
                  newTreenode.contentNodes.indexOf(node),
            ),
          ),
        );
      }
    }

    // --- 3. Dokument aktualisieren ---
    // outlineDoc.root = updatedRoot;

    // --- 4. Selektion setzen ---
    if (moveCollapsedSelectionToInsertedNode) {
      executor.executeCommand(
        ChangeSelectionCommand(
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: newTreenode.titleNode.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
          SelectionChangeType.insertContent,
          'inserted new treenode',
        ),
      );
    }

    // --- 5. Änderungen protokollieren ---
    executor.logChanges(changes);
  }
}

/*
class InsertOutlineTreenodeCommand extends EditCommand {
  InsertOutlineTreenodeCommand({
    required this.existingNode,
    required this.newNode,
    required this.createChild,
    required this.treenodeIndex,
    required this.splitAtDocumentPosition,
    // required this.newDocumentNodeId,
    required this.moveCollapsedSelectionToInsertedNode,
  }) {
    if (splitAtDocumentPosition != null) {
      newDocumentNodeId = uuid.v4();
    }
  }

  // TODO: Operate on Paths rather than on nodes?
  final OutlineTreenode existingNode;
  final OutlineTreenode newNode;
  final bool createChild;
  final int treenodeIndex;
  final DocumentPosition? splitAtDocumentPosition;
  late String? newDocumentNodeId;
  final bool moveCollapsedSelectionToInsertedNode;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    commandLog.fine(
        'executing InsertOutlineTreenodeCommand, appending $newNode behind $existingNode');
    final outlineDoc = context.document as OutlineEditableDocument;

    final changes = <DocumentEdit>[];

    // First add the given new OutlineTreenode at the right position
    if (createChild) {
      outlineDoc.root = TreeEditor.insertChild(
          parent: existingNode,
          child: newNode,
          atIndex: treenodeIndex == -1 ? 0 : treenodeIndex);
    } else {
      assert(existingNode != outlineDoc.root);
      final parentTreenode = outlineDoc.root.findParentOf(existingNode.id)!;
      outlineDoc.root = outlineDoc.root.replaceTreenodeById(
          parentTreenode.id,
          (p) => TreeEditor.insertChild(
                parent: p,
                child: newNode,
                atIndex: treenodeIndex == -1
                    ? outlineDoc.root.getPathTo(existingNode.id)!.last + 1
                    : treenodeIndex,
              ));
      // existingNode.parent!.addChild(
      //   newNode,
      //   treenodeIndex == -1 ? existingNode.childIndex + 1 : treenodeIndex,
      // );
    }

    // Start collecting the document edits we have to log later. Start with
    // the nodes in our new outlinetreenode, which we count as newly inserted
    // nodes.
    final newTitleNodeIndex = outlineDoc.getNodeIndexById(newNode.titleNode.id);
    changes.addAll([
      for (int i = 0; i < newNode.nodesSubtree.length; i++)
        DocumentEdit(
          NodeInsertedEvent(
            newNode.nodesSubtree[i].id,
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
      assert(newDocumentNodeId != null,
          'If splitAtDocumentPosition is given, a newDocumentNodeId must be provided');
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
          newNodeId: newDocumentNodeId!,
          replicateExistingMetadata: true,
        ));
        splitStartIndex++;
      }

      // Now move the latter part of the contentNodes to the new treenode
      final remainingContent =
          existingNode.contentNodes.sublist(0, splitStartIndex);
      final movedContent = existingNode.contentNodes.sublist(splitStartIndex);

      // neuen Treenode mit den verschobenen ContentNodes aktualisieren
      final modifiedNewNode = newNode.copyWith(contentNodes: [
        ...movedContent,
        ...newNode.contentNodes,
      ]);
      final modifiedExistingNode =
          existingNode.copyWith(contentNodes: remainingContent);
      final existingTitleNodeIndex =
          outlineDoc.getNodeIndexById(existingNode.titleNode.id);
      outlineDoc.root.replaceTreenodeById(
        existingNode.id,
        (p) => modifiedExistingNode,
      );
      outlineDoc.root.replaceTreenodeById(
        newNode.id,
        (p) => modifiedNewNode,
      );
      // und entsprechende events absetzen
      while (existingNode.contentNodes.length > splitStartIndex) {
        final nodeId = existingNode.contentNodes[splitStartIndex].id;
        changes.add(DocumentEdit(NodeMovedEvent(
          from: existingTitleNodeIndex + splitStartIndex + 1,
          to: newTitleNodeIndex + 1 + newNode.contentNodes.length,
          nodeId: nodeId,
        )));
      }
    }

    // Now add a TreenodeInsertedDocumentChange
    // changes.add(
    //     DocumentEdit(TreenodeInsertedDocumentChange(newNode.id, newNode.path)));

    executor.executeCommand(
      ChangeSelectionCommand(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            nodeId: newNode.titleNode.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.insertContent,
        'inserted new treenode',
      ),
    );

    executor.logChanges(changes);
  }
}
*/
