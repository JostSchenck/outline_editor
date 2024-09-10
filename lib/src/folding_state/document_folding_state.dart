import 'package:flutter/foundation.dart';
import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

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
/// folding of a branch of tree nodes, or folding of single document nodes
/// in a tree node. Folding a tree node will make all its children invisible,
/// but not the tree node itself. Folding a single document node will make
/// exactly this document node invisible. A document node is visible if itself
/// is not folded and no single ancestor tree node of its own tree node is
/// folded.
class DocumentFoldingState with ChangeNotifier implements Editable {
  DocumentFoldingState({
    required DocumentStructure documentStructure,
  }) : _documentStructure = documentStructure;

  final DocumentStructure _documentStructure;

  /// Maps ids of `DocumentTreeNode`s (not DocumentNodes) to a folding
  /// state. true means folded, false means unfolded
  final Map<String, bool> _treeNodeFoldingStateMap = {};

  /// Maps ids of `DocumentNode`s to a folding state; used when not branches
  /// are folded, but only parts of a tree node
  final Map<String, bool> _docNodeFoldingStateMap = {};

  /// Return visibility of the [DocumentNode] with the given id, taking
  /// folding state of tree nodes as well as document nodes into account.
  bool isVisible(String documentNodeId) {
    // if this particular DocumentNode is already folded, we don't have to
    // look any further
    if (_docNodeFoldingStateMap[documentNodeId] == true) {
      return false;
    }
    // find TreeNode corresponding to the node with id `documentNodeId`
    final myTreeNode =
    _documentStructure.getTreeNodeForDocumentNode(documentNodeId);
    // search all ancestors (not my own tree node) until root and check for
    // folding state
    var ancestor = myTreeNode.parent;
    while (ancestor != null) {
      if (_treeNodeFoldingStateMap[ancestor.id] == true) {
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

  /// Returns whether a certain `DocumentTreeNode` is folded.
  bool isFolded(String treeNodeId) {
    return _treeNodeFoldingStateMap[treeNodeId] ?? false;
  }

  /// Returns whether a certain `DocumentTreeNode` is unfolded.
  bool isUnfolded(String treeNodeId) => !isFolded(treeNodeId);

  /// Folds all [DocumentNode]s in `docNodes`; this folds
  /// individual nodes, no children.
  void foldDocumentNodes(List<String> docNodeIds) =>
      setDocumentNodeFoldingState(docNodeIds, true);

  /// Unfolds all [DocumentNode]s in `docNodes`; this unfolds
  /// individual nodes, no children.
  void unfoldDocumentNodes(List<String> docNodeIds) =>
      setDocumentNodeFoldingState(docNodeIds, false);

  /// Sets all [DocumentNode]s for the IDs in `docNodes` to a folded state;
  /// this folds individual nodes, no children.
  void setDocumentNodeFoldingState(List<String> docNodeIds, bool foldingState) {
    for (var docNodeId in docNodeIds) {
      _docNodeFoldingStateMap[docNodeId] = foldingState;
    }
    notifyListeners();
  }

  /// Sets a [DocumentStructureTreeNode] with id `treeNodeId` to a folding
  /// state; this will hide all child tree nodes, as well.
  void setTreeNodeFoldingState(String treeNodeId, bool foldingState) {
    _treeNodeFoldingStateMap[treeNodeId] = foldingState;
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
