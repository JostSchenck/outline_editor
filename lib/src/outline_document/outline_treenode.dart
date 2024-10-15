import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:outline_editor/src/util/logging.dart';
import 'package:super_editor/super_editor.dart';

const isCollapsedKey = 'isCollapsed';

typedef TreenodePath = List<int>;

class DocumentNodePath {
  DocumentNodePath(
    this.treenodePath,
    this.docNodeIndex,
  );

  TreenodePath treenodePath;
  int docNodeIndex;
}

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
final class OutlineTreenode extends ChangeNotifier with Iterable<DocumentNode> {
  OutlineTreenode({
    List<DocumentNode> documentNodes = const [],
    List<OutlineTreenode>? children,
    this.parent,
    required this.id,
    required this.document,
  }) {
    _documentNodes.addAll(documentNodes);
    if (children != null) _children.addAll(children);
    for (var child in _children) {
      child.parent = this;
    }
  }

  // final List<String> _documentNodeIds = [];
  final List<DocumentNode> _documentNodes = [];
  final List<OutlineTreenode> _children = [];
  OutlineTreenode? parent;
  final String id;
  final Document document;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineTreenode &&
          id == other.id &&
          parent == other.parent &&
          document == other.document &&
          const DeepCollectionEquality()
              .equals(_documentNodes, other._documentNodes) &&
          const DeepCollectionEquality().equals(_children, other._children);

  @override
  int get hashCode =>
      _documentNodes.hashCode ^
      _children.hashCode ^
      id.hashCode ^
      parent.hashCode ^
      document.hashCode;

  List<DocumentNode> get documentNodes => _documentNodes;

  List<DocumentNode> get subtreeDocumentNodes {
    return [
      ..._documentNodes,
      for (var child in _children) ...child.subtreeDocumentNodes,
    ];
  }

  /// Returns the [TreenodePath] to this treenode, which is a List<int> with
  /// the first element being the index of my first ancestor in the root node's
  /// children.
  TreenodePath get path {
    if (parent == null) {
      return [];
    }
    final ret = parent!.path;
    ret.add(parent!.children.indexOf(this));
    return ret;
  }

  /// Returns the [OutlineTreenode] with the given [TreenodePath], if there
  /// is such a descendent, else null.
  OutlineTreenode? getOutlineTreenodeByPath(TreenodePath path) {
    if (path.isEmpty) {
      return null;
    }
    if (path.length == 1) {
      return _children[path.first];
    }
    return _children[path.first].getOutlineTreenodeByPath(path.sublist(1));
  }

  /// Returns the [OutlineTreenode] with the given [DocumentNodePath], if there
  /// is one in this subtree, else null.
  DocumentNode? getDocumentNodeByPath(DocumentNodePath docNodePath) {
    if (docNodePath.treenodePath.isEmpty) {
      return documentNodes[docNodePath.docNodeIndex];
    }
    return _children[docNodePath.treenodePath.first].getDocumentNodeByPath(
      DocumentNodePath(
        docNodePath.treenodePath.sublist(1),
        docNodePath.docNodeIndex,
      ),
    );
  }

  DocumentNode? getDocumentNodeById(String docNodeId) {
    var ret = _documentNodes.firstWhereOrNull((e) => e.id == docNodeId);
    if (ret != null) return ret;
    for (var child in _children) {
      ret = child.getDocumentNodeById(docNodeId);
      if (ret != null) return ret;
    }
    return null;
  }

  DocumentNodePath? getPathToDocumentNode(DocumentNode docNode) {
    final index = _documentNodes.indexOf(docNode);
    if (index != -1) {
      return DocumentNodePath(path, index);
    }
    for (var i = 0; i < _children.length; i++) {
      final ret = _children[i].getPathToDocumentNode(docNode);
      if (ret != null) return ret;
    }
    return null;
  }

  /// The first DocumentNode in a Treenode is considered to be the Head, in
  /// which eg. collapsing status is stored.
  DocumentNode? get headNode =>
      _documentNodes.isEmpty ? null : _documentNodes.first;

  /// Whether this Treenode is considered collapsed.
  bool get isCollapsed =>
      headNode == null ? false : headNode!.metadata[isCollapsedKey] == true;

  /// Sets whether this Treenode is considered collapsed.
  set isCollapsed(bool isCollapsed) {
    if (headNode == null) {
      outlineDocLog
          .fine('Tried to set isCollapsed on Treenode without headNodeId.');
      return;
    }
    outlineDocLog.fine('set isCollapsed to $isCollapsed');
    headNode!.putMetadataValue(isCollapsedKey, isCollapsed);
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
    int index = _documentNodes.indexOf(document.getNodeById(nodeId)!);
    if (index != -1) {
      return index;
    }
    for (var child in _children) {
      index = child.getIndexInChildren(nodeId);
      if (index != -1) {
        return index;
      }
    }
    return -1;
  }

  /// Returns the depth of this TreeNode, 0 meaning a root node.
  int get depth => parent == null ? 0 : parent!.depth + 1;

  /// Returns the first document node in this tree node's whole
  /// subtree (including this node itself), iterating through all descendents
  /// if needed.
  DocumentNode? get firstDocumentNodeInSubtree {
    if (_documentNodes.isNotEmpty) {
      return _documentNodes.first;
    }
    return firstDocumentNodeInChildren;
  }

  /// Returns the first document node in this tree node's child nodes,
  /// iterating through all descendents if needed.
  DocumentNode? get firstDocumentNodeInChildren {
    for (var child in _children) {
      final returnNodeId = child.firstDocumentNodeInSubtree;
      if (returnNodeId != null) {
        return returnNodeId;
      }
    }
    return null;
  }

  /// Returns the last document node in this tree node's whole
  /// subtree (including this node itself), iterating through all descendents
  /// if needed.
  DocumentNode? get lastDocumentNodeInSubtree {
    if (_children.isNotEmpty) {
      return lastDocumentNodeInChildren;
    }
    return _documentNodes.isEmpty ? null : _documentNodes.last;
  }

  /// Returns the last document node in this tree node's child nodes,
  /// iterating through all descendents if needed.
  DocumentNode? get lastDocumentNodeInChildren {
    if (_children.isEmpty) return null;
    for (var child in _children.reversed) {
      final returnNode = child.lastDocumentNodeInSubtree;
      if (returnNode != null) {
        return returnNode;
      }
    }
    return null;
  }

  /// Returns the [OutlineTreenode] that will be evaluated last in this
  /// node's whole subtree.
  OutlineTreenode get lastOutlineTreeNodeInSubtree {
    if (_children.isNotEmpty) {
      return _children.last.lastOutlineTreeNodeInSubtree;
    }
    return this;
  }

  /// Searches this [OutlineTreenode]'s whole subtree and returns
  /// the [OutlineTreenode] that holds the given id to a
  /// [DocumentNode].
  OutlineTreenode? getOutlineTreenodeForDocumentNodeId(String docNodeId) {
    if (documentNodes.where((e) => e.id == docNodeId).isNotEmpty) return this;

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
    final start = firstDocumentNodeInSubtree;
    if (start == null) {
      throw Exception('not a single document node found in subtree');
    }
    final end = lastDocumentNodeInSubtree!;
    return document.getRangeBetween(
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

  /// Returns a [DocumentRange] that spans the subtree of all children of this
  /// [OutlineTreenode], ie. from the first node of this treeNodes
  /// first child node to the last node of the last ancestor.
  DocumentRange get documentRangeForChildren {
    final start = firstDocumentNodeInChildren;
    if (start == null) {
      throw Exception('not a single document node found in subtree');
    }
    final end = lastDocumentNodeInChildren!;
    return document.getRangeBetween(
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

  @override
  Iterator<DocumentNode> get iterator => subtreeDocumentNodes.iterator;

  /// Returns whether the subtree of this [OutlineTreenode] has
  /// equivalent content to the one in `other`.
  ///
  /// Content equivalency compares types of content nodes, and the content
  /// within them, like the text of a paragraph, but ignores node IDs and
  /// ignores the runtime type of the [Document], itself.
  bool hasEquivalentContent(OutlineTreenode other) {
    if (documentNodes.length != other.documentNodes.length) {
      return false;
    }
    if (children.length != other.children.length) {
      return false;
    }
    for (int i = 0; i < documentNodes.length; i++) {
      if (!documentNodes[i].hasEquivalentContent(other.documentNodes[i])) {
        return false;
      }
    }
    for (int i = 0; i < children.length; i++) {
      if (!children[i].hasEquivalentContent(other.children[i])) {
        return false;
      }
    }
    return true;
  }
}

/// An iterator that iterates over all [DocumentNode]s in an [OutlineTreenode]
/// and its children. As with all iterators, behavior in case of changes
/// to the underlying collections is not defined.
// class OutlineDocumentNodeIterator implements Iterator<DocumentNode> {
//   OutlineDocumentNodeIterator(this.root) {
//     final List<DocumentNode> compoundDocumentNodes = [];
//     if (root.documentNodes.isNotEmpty) {
//       compoundDocumentNodes.addAll(root.documentNodes);
//     }
//     for (var child in root.children) {
//       compoundDocumentNodes.addAll(child.documentNodes);
//     }
//     compoundIterator = root.subtreeDocumentNodes.iterator;
//   }
//
//   final OutlineTreenode root;
//   late Iterator<DocumentNode> compoundIterator;
//
//   @override
//   DocumentNode get current => compoundIterator.current;
//
//   @override
//   bool moveNext() => compoundIterator.moveNext();
// }
