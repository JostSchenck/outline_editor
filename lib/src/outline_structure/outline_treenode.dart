import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart';

/// Represents a node in the document structure. Each node contains
/// a list of `documentNodeIds` that point to nodes that represent this one
/// node in the structure, and on a list of other [OutlineTreenode]s
/// as children.
///
/// [OutlineTreenode]s will not persist as objects, but are
/// broken up into their [DocumentNode]s and added to the underlying
/// [MutableDocument]. This means that a [OutlineTreenode] should not
/// contain information apart from its contained documentNodeIds or references
/// to other tree nodes. To enforce this, this class is `final`.
final class OutlineTreenode extends ChangeNotifier {
  OutlineTreenode({
    List<String>? documentNodeIds,
    List<OutlineTreenode>? children,
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
  final List<OutlineTreenode> _children = [];
  OutlineTreenode? parent;
  final String id;
  final Document document;

  List<String> get documentNodeIds => _documentNodeIds;

  List<OutlineTreenode> get children => _children;

  /// Returns the depth of this TreeNode, 0 meaning a root node.
  int get depth => parent==null ? 0 : parent!.depth + 1;

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

  /// Searches this [OutlineTreenode]'s whole subtree and returns
  /// the [OutlineTreenode] that holds the given id to a
  /// [DocumentNode].
  OutlineTreenode? getOutlineTreenodeForDocumentNode(String nodeId) {
    if (documentNodeIds.contains(nodeId)) return this;

    for (var treeNode in children) {
      final childRet = treeNode.getOutlineTreenodeForDocumentNode(nodeId);
      if (childRet != null) return childRet;
    }
    return null;
  }

  /// Returns a [DocumentRange] that spans the entire subtree of this
  /// [OutlineTreenode], ie. from the first node of this treeNode to the last
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
  /// [OutlineTreenode], ie. from the first node of this treeNodes
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
