import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

const documentStructureKey = 'structure';

extension DocumentStructureInContext on EditContext {
  /// Finds and returns the [DocumentStructure] within the [EditContext].
  DocumentStructure get structure =>
      find<DocumentStructure>(documentStructureKey);
}

extension DocumentStructureInEditor on Editor {
  /// Finds and returns the [DocumentStructure] within the [Editor].
  DocumentStructure get documentStructure =>
      context.find<DocumentStructure>(documentStructureKey);
}

/// An Editable representing the structure of a document to be displayed in
/// a structured text editor. There may be different ways of obtaining the
/// structure, independent of the concrete DocumentNodes. Those are handled
/// by subtypes.
abstract class DocumentStructure implements Editable {
  List<DocumentStructureTreeNode> get structure;

  DocumentStructureTreeNode getTreeNodeForDocumentNode(String nodeId) {
    for (var treeNode in structure) {
      final foundNode = treeNode.getTreeNodeForDocumentNode(nodeId);
      if (foundNode != null) return foundNode;
    }
    throw Exception(
        'Did not find DocumentStructureTreeNode for DocumentNode $nodeId');
  }
/*
  /// Adds a [DocumentStructureTreeNode], which can mean a whole branch of
  /// tree nodes, if that tree node has children, at a specified position to
  /// the document. The given [DocumentStructureTreeNode]s will not persist as
  /// objects, but will be broken up into their [DocumentNode]s and added to
  /// the underlying [MutableDocument].
  void addTreeNode({
    DocumentStructureTreeNode? parent,
    DocumentStructureTreeNode? afterSibling,
    DocumentStructureTreeNode? beforeSibling,
  });*/

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
    _treeNodes.clear();
    List<DocumentStructureTreeNode> treeNodeStack = [];
    int lastDepth = 0;
    for (final documentNode in _document) {
      final int depth = documentNode.metadata['depth'] ?? lastDepth;
      lastDepth = depth;

      if (depth == 0) {
        treeNodeStack.clear();
        final newTreeNode = DocumentStructureTreeNode(
          document: _document,
          documentNodeIds: [documentNode.id],
          id: 'tn_${documentNode.id}',
        );
        treeNodeStack.add(newTreeNode);
        // only top level nodes are added to _treeNodes;
        _treeNodes.add(newTreeNode);
      } else if (depth == treeNodeStack.length) {
        // we found a new child to the top one on stack; add it to the
        // children and push it on the stack
        final newTreeNode = DocumentStructureTreeNode(
          document: _document,
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
        final newTreeNode = DocumentStructureTreeNode(
          document: _document,
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

/// Represents a node in the document structure. Each node contains
/// a list of `documentNodeIds` that point to nodes that represent this one
/// node in the structure, and on a list of other [DocumentStructureTreeNode]s
/// as children.
///
/// [DocumentStructureTreeNode]s will not persist as objects, but are
/// broken up into their [DocumentNode]s and added to the underlying
/// [MutableDocument]. This means that a [DocumentStructureTreeNode] should not
/// contain information apart from its contained documentNodeIds or references
/// to other tree nodes. To enforce this, this class is `final`.
final class DocumentStructureTreeNode extends ChangeNotifier {
  DocumentStructureTreeNode({
    List<String>? documentNodeIds,
    List<DocumentStructureTreeNode>? children,
    this.parent,
    required this.id,
    required this.document,
  }) {
    if (documentNodeIds != null) _documentNodeIds.addAll(documentNodeIds);
    if (children != null) _children.addAll(children);
    for (var child in _children) {
      child.parent = this;
    }
  }

  final List<String> _documentNodeIds = [];
  final List<DocumentStructureTreeNode> _children = [];
  DocumentStructureTreeNode? parent;
  final String id;
  final Document document;

  List<String> get documentNodeIds => _documentNodeIds;

  List<DocumentStructureTreeNode> get children => _children;

  /// Returns the id of the first document node in this tree node's whole
  /// subtree (including this node itself), iterating through all descendents
  /// if needed.
  String? get firstDocumentNodeIdInSubtree {
    if (_documentNodeIds.isNotEmpty) {
      return _documentNodeIds.first;
    }
    return firstDocumentNodeIdInChildren;
  }

  /// Returns the id of the first document node in this tree node's child nodes,
  /// iterating through all descendents if needed.
  String? get firstDocumentNodeIdInChildren {
    for (var child in _children) {
      final returnNodeId = child.firstDocumentNodeIdInSubtree;
      if (returnNodeId != null) {
        return returnNodeId;
      }
    }
    return null;
  }

  /// Returns the id of the last document node in this tree node's whole
  /// subtree (including this node itself), iterating through all descendents
  /// if needed.
  String? get lastDocumentNodeIdInSubtree {
    if (_children.isNotEmpty) {
      return lastDocumentNodeIdInChildren;
    }
    return _documentNodeIds.isEmpty ? null : _documentNodeIds.last;
  }

  /// Returns the id of the last document node in this tree node's child nodes,
  /// iterating through all descendents if needed.
  String? get lastDocumentNodeIdInChildren {
    if (_children.isEmpty) return null;
    for (var child in _children.reversed) {
      final returnNodeId = child.lastDocumentNodeIdInSubtree;
      if (returnNodeId != null) {
        return returnNodeId;
      }
    }
    return null;
  }

  /// Searches this [DocumentStructureTreeNode]'s whole subtree and returns
  /// the [DocumentStructureTreeNode] that holds the given id to a
  /// [DocumentNode].
  DocumentStructureTreeNode? getTreeNodeForDocumentNode(String nodeId) {
    if (documentNodeIds.contains(nodeId)) return this;

    for (var treeNode in children) {
      final childRet = treeNode.getTreeNodeForDocumentNode(nodeId);
      if (childRet != null) return childRet;
    }
    return null;
  }

  /// Returns a [DocumentRange] that spans the entire subtree of this
  /// [TreeNode], ie. from the first node of this treeNode to the last
  /// node of the last ancestor.
  DocumentRange get documentRangeForSubtree {
    final start = firstDocumentNodeIdInSubtree;
    if (start == null) {
      throw Exception('not a single document node found in subtree');
    }
    final end = lastDocumentNodeIdInSubtree!;
    return document.getRangeBetween(
      DocumentPosition(
        nodeId: start,
        nodePosition: document.getNodeById(start)!.beginningPosition,
      ),
      DocumentPosition(
        nodeId: end,
        nodePosition: document.getNodeById(end)!.endPosition,
      ),
    );
  }

  /// Returns a [DocumentRange] that spans the subtree of all children of this
  /// [DocumentStructureTreeNode], ie. from the first node of this treeNodes
  /// first child node to the last node of the last ancestor.
  DocumentRange get documentRangeForChildren {
    final start = firstDocumentNodeIdInChildren;
    if (start == null) {
      throw Exception('not a single document node found in subtree');
    }
    final end = lastDocumentNodeIdInChildren!;
    return document.getRangeBetween(
      DocumentPosition(
        nodeId: start,
        nodePosition: document.getNodeById(start)!.beginningPosition,
      ),
      DocumentPosition(
        nodeId: end,
        nodePosition: document.getNodeById(end)!.endPosition,
      ),
    );
  }
}
