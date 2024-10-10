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
  }) {
    _root = OutlineTreenode(id: 'root', document: this);
    rebuildStructure();
  }

  late OutlineTreenode _root;

  @override
  OutlineTreenode get root => _root;

  @override
  bool isCollapsed(String nodeId) =>
      getTreeNodeForDocumentNodeId(nodeId).isCollapsed;

  @override
  void setCollapsed(String nodeId, bool isCollapsed) {
    getTreeNodeForDocumentNodeId(nodeId).isCollapsed = isCollapsed;
  }

  @override
  bool isHidden(String nodeId) =>
      getNodeById(nodeId)!.getMetadataValue(isHiddenKey) == true;

  @override
  void setHidden(String nodeId, bool isHidden) {
    getNodeById(nodeId)!.putMetadataValue(isHiddenKey, isHidden);
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
    _root = OutlineTreenode(document: this, id: 'root');
    List<OutlineTreenode> treeNodeStack = [root];
    // we start at 1 because our already existing root node is depth 0 and every
    // node found will be put into a child.
    int lastDepth = 1;
    for (final documentNode in this) {
      final int depth = documentNode.metadata[nodeDepthKey] ?? lastDepth;
      lastDepth = depth;
      final newTreeNode = OutlineTreenode(
        document: this,
        documentNodeIds: [documentNode.id],
        id: 'tn_${documentNode.id}',
      );
      if (depth == treeNodeStack.length) {
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
