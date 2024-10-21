import 'package:outline_editor/src/outline_document/outline_treenode.dart';
import 'package:super_editor/super_editor.dart';

const isHiddenKey = 'isHidden';

/// Mixin to be used or implemented implemented by the Document
/// class to be used in an outline editor.
abstract mixin class OutlineDocument implements Document {
  OutlineTreenode get root;

  OutlineTreenode getOutlineTreenodeForDocumentNodeId(String nodeId) {
    final ret = root.getOutlineTreenodeForDocumentNodeId(nodeId);
    if (ret == null) {
      throw Exception('Did not find OutlineTreenode for DocumentNode $nodeId');
    }
    return ret;
  }

  int getTreenodeDepth(String nodeId) =>
      getOutlineTreenodeForDocumentNodeId(nodeId).depth;

  TreenodePath getOutlinePath(String nodeId) =>
      getOutlineTreenodeForDocumentNodeId(nodeId).path;

  OutlineTreenode getOutlineTreenodeByPath(TreenodePath path) {
    final ret = root.getOutlineTreenodeByPath(path);
    if (ret == null) {
      throw Exception('Could not find OutlineTreenode for path $path');
    }
    return ret;
  }

  // test
  OutlineTreenode getOutlineTreenodeById(String id) {
    final ret = root.getOutlineTreenodeById(id);
    if (ret == null) {
      throw Exception('Could not find OutlineTreenode for id $id');
    }
    return ret;
  }

  OutlineTreenode? getOutlineTreenodeBeforeTreenode(OutlineTreenode treenode) {
    if (treenode.parent==null) return null;
    final childIndex = treenode.parent!.children.indexOf(treenode);
    if (childIndex==0) {
      return treenode.parent;
    }
    return (treenode.parent!.children[childIndex-1].lastOutlineTreeNodeInSubtree);
  }

  /// At which position in the parent's content a certain [DocumentNode] is
  /// located, ie. 0 for the first child, 1 for the second, etc. Returns -1 if
  /// it does not find nodeId. The result can be used for component building.
  int getIndexInChildren(String docNodeId) {
    final treeNode = getOutlineTreenodeForDocumentNodeId(docNodeId);
    for (var i = 0; i < treeNode.documentNodes.length; i++) {
      if (treeNode.documentNodes[i].id == docNodeId) {
        return i;
      }
    }
    return -1;
  }

  /// Returns whether the specified [OutlineTreenode] with id `treeNodeID` '
  /// is collapsed (ie. child [OutlineTreenode]s with their
  /// [DocumentNode]s hidden, not this [OutlineTreenode]'s own [DocumentNode]s).
  bool isCollapsed(String treeNodeId);

  /// Sets whether the specified [OutlineTreenode] with id `treeNodeID`
  /// is collapsed (ie. child [OutlineTreenode]s with their
  ///
  void setCollapsed(String treeNodeId, bool isCollapsed);

  /// Returns whether the specified [DocumentNode] with id `nodeId` is
  /// hidden.
  bool isHidden(String documentNodeId);

  void setHidden(String documentNodeId, bool isHidden);

  /// Return visibility of the [DocumentNode] with the given id, taking
  /// folding state of tree nodes as well as document nodes into account.
  bool isVisible(String documentNodeId) {
    // if this particular DocumentNode is already hidden, we don't have to
    // look any further
    if (isHidden(documentNodeId)) {
      return false;
    }
    // find TreeNode corresponding to the node with id `documentNodeId`
    final myTreeNode = getOutlineTreenodeForDocumentNodeId(documentNodeId);
    // search all ancestors (not my own tree node) until root and check if one
    // is collapsed
    var ancestor = myTreeNode.parent;
    while (ancestor != null) {
      if (ancestor.isCollapsed) {
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

  /// Returns the last visible [DocumentNode] in the document before `pos`, or the node
  /// at `pos` itself, if it is visible. Note that
  /// this may not correspond to a selectable component later on. The first
  /// node in a document is always visible, so this method will always return
  /// a node.
  DocumentNode getLastVisibleDocumentNode(DocumentPosition pos) {
    if (isVisible(pos.nodeId)) {
      // nothing to do; the position is not in a hidden node.
      return getNodeById(pos.nodeId)!;
    }
    // because the node at [0] must always be a root node, and root nodes must
    // always be visible, pos.nodeId must at this point be >0
    assert(getNodeIndexById(pos.nodeId) > 0);
    for (var i = getNodeIndexById(pos.nodeId) - 1; i > 0; i--) {
      if (isVisible(elementAt(i).id)) {
        return elementAt(i);
      }
    }
    throw Exception('No visible node found before $pos');
  }

  /// Returns the first visible node in the document after `pos`, or the node
  /// at `pos` itself, if it is visible. Note that
  /// this may not correspond to a selectable component later on. Returns
  /// null, if there is no visible node later in the document.
  DocumentNode? getNextVisibleDocumentnode(DocumentPosition pos);

  void rebuildStructure();
}
