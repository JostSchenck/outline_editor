import 'package:outline_editor/src/outline_document/outline_document.dart';
import 'package:outline_editor/src/outline_document/outline_treenode.dart';
import 'package:outline_editor/src/util/logging.dart';
import 'package:super_editor/super_editor.dart';

const nodeDepthKey = 'depth';

/// A MutableDocument which gets structured according to the `depth` entry
/// that every Node in the Document has to have. Node depths must be legal,
/// so for example a node after a node of depth `d` may have at most a depth
/// of `d+1`.
class OutlineMutableDocument extends MutableDocument with OutlineDocument {
  OutlineMutableDocument({
    super.nodes,
  });

  @override
  final List<OutlineTreenode> rootNodes = [];

  @override
  bool isCollapsed(String nodeId) =>
      getTreeNodeForDocumentNode(nodeId).isCollapsed;

  @override
  void setCollapsed(String nodeId, bool isCollapsed) {
    getTreeNodeForDocumentNode(nodeId).isCollapsed = isCollapsed;
  }

  @override
  bool isHidden(String nodeId) =>
      getNodeById(nodeId)!.getMetadataValue(isHiddenKey) == true;

  @override
  void setHidden(String nodeId, bool isHidden) {
    getNodeById(nodeId)!.putMetadataValue(isHiddenKey, isHidden);
  }

  @override
  OutlineTreenode getTreeNodeForDocumentNode(String nodeId) {
    for (var treeNode in rootNodes) {
      final foundNode = treeNode.getOutlineTreenodeForDocumentNode(nodeId);
      if (foundNode != null) return foundNode;
    }
    throw Exception(
        'Did not find DocumentStructureTreeNode for DocumentNode $nodeId');
  }

  @override
  int getIndentationLevel(String nodeId) =>
      getTreeNodeForDocumentNode(nodeId).depth;

  /// Return visibility of the [DocumentNode] with the given id, taking
  /// folding state of tree nodes as well as document nodes into account.
  @override
  bool isVisible(String documentNodeId) {
    // if this particular DocumentNode is already hidden, we don't have to
    // look any further
    if (isHidden(documentNodeId)) {
      return false;
    }
    // find TreeNode corresponding to the node with id `documentNodeId`
    final myTreeNode = getTreeNodeForDocumentNode(documentNodeId);
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

  @override
  DocumentNode getLastVisibleNode(DocumentPosition pos) {
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

  @override
  DocumentNode? getNextVisibleNode(DocumentPosition pos) {
    for (var i = getNodeIndexById(pos.nodeId); i < nodeCount; i++) {
      if (isVisible(elementAt(i).id)) {
        return elementAt(i);
      }
    }
    return null;
  }

  @override
  void rebuildStructure() {
    outlineDocLog
        .fine('rebuilding OutlineDocument structure from depth metadata');
    rootNodes.clear();
    List<OutlineTreenode> treeNodeStack = [];
    int lastDepth = 0;
    for (final documentNode in this) {
      final int depth = documentNode.metadata[nodeDepthKey] ?? lastDepth;
      lastDepth = depth;
      final newTreeNode = OutlineTreenode(
        document: this,
        documentNodeIds: [documentNode.id],
        id: 'tn_${documentNode.id}',
      );
      if (depth == 0) {
        if (treeNodeStack.length==1) {
          // this is another paragraph right after the last on depth 0,
          // treat this a documentnode to the same root node, rather than
          // a sibling root node.
          treeNodeStack.last.documentNodeIds.add(documentNode.id);
        } else {
          treeNodeStack.clear();
          treeNodeStack.add(newTreeNode);
          rootNodes.add(newTreeNode);
        }
      } else if (depth == treeNodeStack.length) {
        // we found a new child to the top one on stack; add it to the
        // children and push it on the stack
        treeNodeStack.last.addChild(newTreeNode);
        treeNodeStack.add(newTreeNode);
      } else if (depth == treeNodeStack.length - 1) {
        // we found a paragraph that is on the same depth as the
        // paragraph before. Treat this as part of the same treenode
        // instead of creating siblings.
        treeNodeStack.last.documentNodeIds.add(documentNode.id);
      } else if (depth > 0 && depth <= treeNodeStack.length - 2) {
        // we found a new sibling to one on stack; add it to the children of
        // the parent of the last one on this depth of stack, then shorten the
        // stack to this one and push our new treeNode
        treeNodeStack[depth - 1].addChild(newTreeNode);
        treeNodeStack.removeRange(depth, treeNodeStack.length);
        treeNodeStack.add(newTreeNode);
      } else {
        if (depth > treeNodeStack.length) {
          throw Exception('depth may only move up in single steps '
              'but a node of depth $depth was found following one of '
              'depth ${treeNodeStack.length - 1}');
        }
        if (depth < 0) {
          throw Exception('illegal depth of $depth found');
        }
      }
    }
  }
}
