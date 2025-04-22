import 'package:outline_editor/outline_editor.dart';

const isHiddenKey = 'isHidden';

/// Mixin to be used or implemented implemented by the Document
/// class to be used in an outline editor.
abstract mixin class OutlineDocument<T extends OutlineTreenode>
    implements Document {
  T get root;

  T getOutlineTreenodeForDocumentNodeId(String nodeId) {
    final ret = root.getOutlineTreenodeByDocumentNodeId(nodeId) as T?;
    if (ret == null) {
      throw Exception('Did not find OutlineTreenode for DocumentNode $nodeId');
    }
    return ret;
  }

  int getTreenodeDepth(String nodeId) =>
      getOutlineTreenodeForDocumentNodeId(nodeId).depth;

  TreenodePath getOutlinePathByDocNodeId(String docNodeId) =>
      getOutlineTreenodeForDocumentNodeId(docNodeId).path;

  T getOutlineTreenodeByPath(TreenodePath path) {
    if (path.isEmpty) return root;
    final ret = root.getOutlineTreenodeByPath(path) as T?;
    if (ret == null) {
      throw Exception('Could not find OutlineTreenode for path $path');
    }
    return ret;
  }

  // test
  T getOutlineTreenodeById(String treenodeId) {
    final ret = root.getOutlineTreenodeById(treenodeId) as T?;
    if (ret == null) {
      throw Exception('Could not find OutlineTreenode for id $treenodeId');
    }
    return ret;
  }

  // test
  T getOutlineTreenodeByDocumentNodeId(String docNodeId) {
    final ret = root.getOutlineTreenodeByDocumentNodeId(docNodeId) as T?;
    if (ret == null) {
      throw Exception(
          'Could not find OutlineTreenode for docNodeId $docNodeId');
    }
    return ret;
  }

  /// Returns the OutlineTreenode directly preceding this OutlineTreenode in
  /// presentation. This can be a sibling, a parent, or even just some cousin.
  T? getOutlineTreenodeBeforeTreenode(T treenode) {
    if (treenode.parent == null) return null;
    final childIndex = treenode.childIndex;
    if (childIndex == 0) {
      // omit logical root node
      if (treenode.parent?.parent == null) return null;
      return treenode.parent as T?;
    }
    return (treenode
        .parent!.children[childIndex - 1].lastOutlineTreeNodeInSubtree as T);
  }

  /// Returns the OutlineTreenode directly following this OutlineTreenode in
  /// presentation. This can be a sibling, an uncle, or even just some cousin.
  T? getOutlineTreenodeAfterTreenode(T treenode) {
    // if we have children, move to the first child
    if (treenode.children.isNotEmpty) {
      return treenode.children.first as T;
    }
    // So we don't. If we are the root node, there's nothing to move to
    if (treenode.parent == null) return null;
    // if we happen to have a directly following sibling, go there, if not,
    // return our next ancestor's sibling
    T currentTreenode = treenode;
    while (currentTreenode.parent != null) {
      if (currentTreenode.parent!.children.length >
          currentTreenode.childIndex + 1) {
        return currentTreenode.parent!.children[currentTreenode.childIndex + 1]
            as T;
      }
      currentTreenode = currentTreenode.parent! as T;
    }
    return null;
  }

  /// At which position in the parent's content a certain [DocumentNode] is
  /// located, ie. 0 for the first child, 1 for the second, etc. Returns -1 if
  /// it does not find nodeId. The result is used for component building.
  int getIndexInChildren(String docNodeId) {
    final treeNode = getOutlineTreenodeForDocumentNodeId(docNodeId);
    for (var i = 0; i < treeNode.nodes.length; i++) {
      if (treeNode.nodes[i].id == docNodeId) {
        return i;
      }
    }
    return -1;
  }

  /// At which position in a treenode's or its children's documentNodes
  /// the DocumentNode with nodeId is located, ie. 0 for first position, 1 for the
  /// second, etc. Returns -1 if it does not find nodeId.
  /// This is mainly used for component building: For example, the first
  /// node in a treenodes content might be decorated with a button or similar.
  int getIndexInSubtree(OutlineTreenode treenode, String nodeId) {
    int index = treenode.nodes.indexOf(getNodeById(nodeId)!);
    if (index != -1) {
      return index;
    }
    for (var child in treenode.children) {
      index = getIndexInSubtree(child, nodeId);
      if (index != -1) {
        return index;
      }
    }
    return -1;
  }

  /// Returns a [DocumentRange] that spans the entire subtree of the given
  /// [OutlineTreenode], ie. from the first node of this treenode to the last
  /// node of the last ancestor.
  DocumentRange getDocumentRangeForSubtree(OutlineTreenode treenode) {
    final start = treenode.firstDocumentNodeInSubtree;
    if (start == null) {
      throw Exception('not a single document node found in subtree');
    }
    final end = treenode.lastDocumentNodeInSubtree!;
    return getRangeBetween(
      DocumentPosition(
        nodeId: start.id,
        nodePosition: start.beginningPosition,
      ),
      DocumentPosition(
        nodeId: end.id,
        nodePosition: end.endPosition,
      ),
    );
  }

  /// Returns a [DocumentRange] that spans the subtree of all children of the
  /// given [OutlineTreenode], ie. from the first node of this treeNodes
  /// first child node to the last node of the last ancestor.
  DocumentRange getDocumentRangeForChildren(OutlineTreenode treenode) {
    final start = treenode.firstDocumentNodeInChildren;
    if (start == null) {
      throw Exception('not a single document node found in subtree');
    }
    final end = treenode.lastDocumentNodeInChildren!;
    return getRangeBetween(
      DocumentPosition(
        nodeId: start.id,
        nodePosition: start.beginningPosition,
      ),
      DocumentPosition(
        nodeId: end.id,
        nodePosition: end.endPosition,
      ),
    );
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
    final myDocNode = getNodeById(documentNodeId);
    final myTreeNode = getOutlineTreenodeForDocumentNodeId(documentNodeId);
    if (myDocNode is TitleNode) {
      return myTreeNode.isVisible;
    } else {
      return !myTreeNode.hasContentHidden &&
          !myTreeNode.isCollapsed &&
          myTreeNode.isVisible;
    }
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
    for (var i = getNodeIndexById(pos.nodeId) - 1; i >= 0; i--) {
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
}
