import 'package:flutter/foundation.dart';
import 'package:outline_editor/outline_editor.dart';

const documentFoldingStateKey = 'foldingState';

extension DocumentFoldingStateInContext on EditContext {
  /// Finds and returns the [DocumentFoldingState] within the [EditContext].
  DocumentFoldingState get foldingState =>
      find<DocumentFoldingState>(documentFoldingStateKey);
}

extension DocumentFoldingStateInEditor on Editor {
  /// Finds and returns the [DocumentFoldingState] within the [Editor].
  DocumentFoldingState get foldingState =>
      context.find<DocumentFoldingState>(documentFoldingStateKey);
}

/// The state of folding of a document. This allows for two types of folding:
/// folding of a branch of tree nodes, or hiding of single document nodes
/// in a tree node. Folding a tree node will make all its children invisible,
/// but not the tree node itself. Hiding a single document node will make
/// exactly this document node invisible. A document node is visible if itself
/// is not folded and no single ancestor tree node of its own tree node is
/// folded.
class DocumentFoldingState with ChangeNotifier implements Editable {
  DocumentFoldingState({
    required this.document,
  });

  final OutlineDocument document;

  /// Maps ids of `DocumentTreeNode`s (not DocumentNodes) to a folding
  /// state. true means collapsed, false means Expanded
  final Map<String, bool> _treeNodeCollapsedStateMap = {};

  /// Maps ids of `DocumentNode`s to a hiding state; used when not branches
  /// are folded, but only documentnodes hidden; true means hidden
  final Map<String, bool> _docNodeHideStateMap = {};

  /// Return visibility of the [DocumentNode] with the given id, taking
  /// folding state of tree nodes as well as document nodes into account.
  bool isVisible(String documentNodeId) {
    // if this particular DocumentNode is already hidden, we don't have to
    // look any further
    if (_docNodeHideStateMap[documentNodeId] == true) {
      return false;
    }
    // find TreeNode corresponding to the node with id `documentNodeId`
    final myTreeNode =
    document.getTreeNodeForDocumentNode(documentNodeId);
    // search all ancestors (not my own tree node) until root and check if one
    // is collapsed
    var ancestor = myTreeNode.parent;
    while (ancestor != null) {
      if (_treeNodeCollapsedStateMap[ancestor.id] == true) {
        // found an ancestor that is folded, so we as a descendent
        // are, too
        return false;
      }
      ancestor = ancestor.parent;
    }
    // root nodes are never hidden. All ancestors until root are visible, so
    // we are, too
    return true;
  }

  /// Returns whether a certain `DocumentTreeNode` is collapsed.
  bool isCollapsed(String treeNodeId) {
    return _treeNodeCollapsedStateMap[treeNodeId] ?? false;
  }

  /// Returns whether a certain `DocumentTreeNode` is expanded.
  bool isExpanded(String treeNodeId) => !isCollapsed(treeNodeId);

  /// Hides all [DocumentNode]s in `docNodes`; this hides
  /// individual nodes, it folds no children.
  void hideDocumentNodes(List<String> docNodeIds) =>
      setDocumentNodeHideState(docNodeIds, true);

  /// Shows all [DocumentNode]s in `docNodes`; this shows
  /// individual nodes, it unfolds no children.
  void showDocumentNodes(List<String> docNodeIds) =>
      setDocumentNodeHideState(docNodeIds, false);

  /// Sets all [DocumentNode]s for the IDs in `docNodes` to a folded state;
  /// this folds individual nodes, no children.
  void setDocumentNodeHideState(List<String> docNodeIds, bool hidden) {
    for (var docNodeId in docNodeIds) {
      _docNodeHideStateMap[docNodeId] = hidden;
    }
    notifyListeners();
  }

  /// Sets a [DocumentStructureTreeNode] with id `treeNodeId` to a collapsed
  /// state; if collapsed, all child tree nodes will be considered hidden.
  void setTreeNodeCollapsedState(String treeNodeId, bool foldingState) {
    _treeNodeCollapsedStateMap[treeNodeId] = foldingState;
    notifyListeners();
  }

  @override
  void onTransactionEnd(List<EditEvent> edits) {
    // TODO: implement onTransactionEnd
  }

  @override
  void onTransactionStart() {
    // TODO: implement onTransactionStart
  }

  @override
  void reset() {
    // TODO: implement reset
  }
}
