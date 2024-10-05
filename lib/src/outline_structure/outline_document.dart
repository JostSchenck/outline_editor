import 'package:outline_editor/src/outline_structure/outline_treenode.dart';
import 'package:super_editor/super_editor.dart';

/// Interface class that has to be implemented by the Document
/// class to be used in an outline editor.
abstract class OutlineDocument {
  List<OutlineTreenode> get rootNodes;

  OutlineTreenode getTreeNodeForDocumentNode(String nodeId);

  int getIndentationLevel(String nodeId);

  void rebuildStructure();
}

const nodeDepthKey = 'depth';

mixin OutlineDocumentByNodeDepthMetadata on Document
    implements OutlineDocument {
  final List<OutlineTreenode> _rootNodes = [];

  @override
  List<OutlineTreenode> get rootNodes => _rootNodes;

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

  @override
  void rebuildStructure() {
    _rootNodes.clear();
    List<OutlineTreenode> treeNodeStack = [];
    int lastDepth = 0;
    for (final documentNode in this) {
      final int depth = documentNode.metadata[nodeDepthKey] ?? lastDepth;
      lastDepth = depth;

      if (depth == 0) {
        treeNodeStack.clear();
        final newTreeNode = OutlineTreenode(
          document: this,
          documentNodeIds: [documentNode.id],
          id: 'tn_${documentNode.id}',
        );
        treeNodeStack.add(newTreeNode);
        // only top level nodes are added to _treeNodes;
        _rootNodes.add(newTreeNode);
      } else if (depth == treeNodeStack.length) {
        // we found a new child to the top one on stack; add it to the
        // children and push it on the stack
        final newTreeNode = OutlineTreenode(
          document: this,
          documentNodeIds: [documentNode.id],
          parent: treeNodeStack.last,
          id: 'tn_${documentNode.id}',
        );
        treeNodeStack.last.children.add(newTreeNode);
        treeNodeStack.add(newTreeNode);
      } else if (depth <= treeNodeStack.length - 1) {
        // we found a new sibling to one on stack; add it to the children of
        // the parent of the last one on this depth of stack, then shorten the
        // stack to this one and push our new treeNode
        final newTreeNode = OutlineTreenode(
          document: this,
          documentNodeIds: [documentNode.id],
          parent: treeNodeStack[depth - 1],
          id: 'tn_${documentNode.id}',
        );
        treeNodeStack[depth - 1].children.add(newTreeNode);
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

/// A MutableDocument which gets structured according to the `depth` entry
/// that every Node in the Document has to have. Node depths must be legal,
/// so for example a node after a node of depth `d` may have at most a depth
/// of `d+1`.
class OutlineMutableDocumentByNodeDepthMetadata extends MutableDocument
    with OutlineDocumentByNodeDepthMetadata {
  OutlineMutableDocumentByNodeDepthMetadata({super.nodes, });
}
