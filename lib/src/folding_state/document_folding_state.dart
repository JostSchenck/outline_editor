import 'package:flutter/foundation.dart';
import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

abstract class DocumentFoldingState with ChangeNotifier {
  DocumentFoldingState({
    required DocumentStructure documentStructure,
  }) : _documentStructure = documentStructure;

  final DocumentStructure _documentStructure;

  /// Returns whether the component for a given [DocumentNode]  is supposed to
  /// be shown.
  bool isVisible(String documentNodeId);

  /// Returns whether the component for a given [DocumentNode] is supposed to
  /// be *not* shown.
  bool isInvisible(String documentNodeId) => !isVisible(documentNodeId);
}

class ChildOnlyDocumentFoldingState extends DocumentFoldingState
    implements Editable {

  ChildOnlyDocumentFoldingState({required super.documentStructure});

  /// Maps ids of `DocumentTreeNode`s (not DocumentNodes) to a folding
  /// state.
  final Map<String, bool> _foldingStateMap = {};


  @override
  bool isVisible(String documentNodeId) {
    // find TreeNode corresponding to the node with id `documentNodeId`
    final myTreeNode =
        _documentStructure.getTreeNodeForDocumentNode(documentNodeId);
    // root nodes are never hidden
    var ancestor = myTreeNode.parent;
    while (ancestor != null) {
      if (_foldingStateMap[ancestor.id] == false){
        // found an ancestor that is invisible, so we as a descendent
        // are, too
        return false;
      }
      ancestor = ancestor.parent;
    }
    // all ancestors until root are visible, so we are, too
    return true;
  }

  bool isFolded(String treeNodeId) {
    return _foldingStateMap[treeNodeId] ?? false;
  }

  /// Returns whether a certain `DocumentTreeNode` is unfolded.
  bool isUnfolded(String treeNodeId) => !isFolded(treeNodeId);

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
