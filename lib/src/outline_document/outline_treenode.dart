import 'package:flutter/foundation.dart';
import 'package:outline_editor/src/util/logging.dart';
import 'package:super_editor/super_editor.dart';

const isCollapsedKey = 'isCollapsed';

typedef OutlinePath = List<int>;

/// Represents a treenode in the document structure. Each treenode contains
/// a list of `documentNodeIds` that point to [DocumentNodes] that represent
/// this one Treenode, and a list of other [OutlineTreenode]s
/// as children.
///
/// [OutlineTreenode]s will not persist as objects, but are
/// broken up into their [DocumentNode]s and added to the underlying
/// [MutableDocument]. This means that an [OutlineTreenode] should not
/// contain information apart from its contained documentNodeIds or references
/// to other tree nodes. To enforce this, this class is `final`.
final class OutlineTreenode extends ChangeNotifier {
  OutlineTreenode({
    List<String> documentNodeIds = const [],
    List<OutlineTreenode>? children,
    this.parent,
    required this.id,
    required this.document,
  }) {
    _documentNodeIds.addAll(documentNodeIds);
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

  /// Returns the [OutlinePath] to this treenode, which is a List<int> with
  /// the first element being the index of my first ancestor in the root node's
  /// children.
  OutlinePath get path {
    if (parent==null) {
      return [];
    }
    final ret = parent!.path;
    ret.add(parent!.children.indexOf(this));
    return ret;
  }

  /// The first DocumentNode in a Treenode is considered to be the Head, in
  /// which eg. collapsing status is stored.
  String? get headNodeId => _documentNodeIds.isEmpty ? null : _documentNodeIds.first;

  /// Whether this Treenode is considered collapsed.
  bool get isCollapsed =>
      headNodeId==null ? false: document.getNodeById(headNodeId!)!.metadata[isCollapsedKey] == true;

  /// Sets whether this Treenode is considered collapsed.
  set isCollapsed(bool isCollapsed) {
    if (headNodeId== null) {
      outlineDocLog.fine(
          'Tried to set isCollapsed on Treenode without headNodeId.');
      return;
    }
    document
        .getNodeById(headNodeId!)!
        .putMetadataValue(isCollapsedKey, isCollapsed);
    notifyListeners();
  }

  /// Returns a list of the Treenodes representing children of this Treenode.
  List<OutlineTreenode> get children => _children;

  // this must not be used for document manipulation, but only on
  // structure rebuilding in classes derived from OutlineDocument.
  void addChild(OutlineTreenode child) {
    _children.add(child);
    child.parent = this;
    notifyListeners();
  }

  // this must not be used for document manipulation, but only on
  // structure rebuilding in classes derived from OutlineDocument.
  void removeChild(OutlineTreenode child) {
    _children.remove(child);
    child.parent = null;
    notifyListeners();
  }

  /// At which position in this treenode's or its children's documentNodes
  /// the DocumentNode with nodeId is located, ie. 0 for first position, 1 for the
  /// second, etc. Returns -1 if it does not find nodeId.
  /// This is mainly used for component building: For example, the first
  /// node in a treenodes content might be decorated with a button or similar.
  int getIndexInChildren(String nodeId) {
    int index = _documentNodeIds.indexOf(nodeId);
    if (index != -1) {
      return index;
    }
    for (var child in _children) {
      index = child.getIndexInChildren(nodeId);
      if (index!=-1) {
        return index;
      }
    }
    return -1;
  }

  /// Returns the depth of this TreeNode, 0 meaning a root node.
  int get depth => parent == null ? 0 : parent!.depth + 1;

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
  OutlineTreenode? getOutlineTreenodeForDocumentNodeId(String docNodeId) {
    if (documentNodeIds.contains(docNodeId)) return this;

    for (var treeNode in children) {
      final childRet = treeNode.getOutlineTreenodeForDocumentNodeId(docNodeId);
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
