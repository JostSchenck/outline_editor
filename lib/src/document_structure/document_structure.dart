import 'package:super_editor/super_editor.dart';

///
abstract class DocumentStructure implements Editable {
  List<DocumentStructureTreeNode> get structure;

  void rebuildStructure();

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

/// extracts document structure based on node metadata, where an integer
/// for key "depth" is expected, with 0 being root. This will assume that
/// only one DocumentNode belongs to one TreeNode
class MetadataDepthDocumentStructure extends DocumentStructure {
  MetadataDepthDocumentStructure(this._document) {
    rebuildStructure();
  }

  final MutableDocument _document;
  final List<DocumentStructureTreeNode> _treeNodes = [];

  @override
  List<DocumentStructureTreeNode> get structure => _treeNodes;

  @override
  void rebuildStructure() {
    // TODO: implement rebuildStructure
    _treeNodes.clear();
    List<DocumentStructureTreeNode> treeNodeStack = [];
    for (final documentNode in _document) {
      final int depth = documentNode.metadata['depth'];
      final newTreeNode =
          DocumentStructureTreeNode(documentNodeIds: [documentNode.id]);

      if (depth == 0) {
        treeNodeStack.clear();
        treeNodeStack.add(newTreeNode);
        // only top level nodes are added to _treeNodes;
        _treeNodes.add(newTreeNode);
      } else if (depth == treeNodeStack.length) {
        // we found a new child to the top one on stack; add it to the
        // children and push it on the stack
        treeNodeStack.last.children.add(newTreeNode);
        treeNodeStack.add(newTreeNode);
      } else if (depth <= treeNodeStack.length - 1) {
        // we found a new sibling to one on stack; add it to the children of
        // the parent of the last one on this depth of stack, then shorten the
        // stack to this one and push our new treeNode
        treeNodeStack[depth - 1].children.add(newTreeNode);
        treeNodeStack.removeRange(depth, treeNodeStack.length);
        treeNodeStack.add(newTreeNode);
      } else {
        if (depth > treeNodeStack.length) {
          throw Exception('depth may only move up in single steps '
             'but a node of depth $depth was found following one of '
             'depth ${treeNodeStack.length-1}');
        }
        if (depth < 0) {
          throw Exception('illegal depth of $depth found');
        }
      }
    }
  }
}

/// Represents a node in the document structure. Each node contains
/// a list of `documentNodeIds` that point to nodes that represent this one
/// node in the structure, and on a list of other [DocumentStructureTreeNode]s
/// as children.
class DocumentStructureTreeNode {
  DocumentStructureTreeNode({
    List<String>? documentNodeIds,
    List<DocumentStructureTreeNode>? children,
  }) {
    if (documentNodeIds!=null) _documentNodeIds.addAll(documentNodeIds);
    if (children!=null) _children.addAll(children);
  }

  final List<String> _documentNodeIds = [];
  final List<DocumentStructureTreeNode> _children = [];

  List<String> get documentNodeIds => _documentNodeIds;
  List<DocumentStructureTreeNode> get children => _children;
}
