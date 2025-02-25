import 'dart:math';

import 'package:collection/collection.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

import '../infrastructure/uuid.dart';

const isCollapsedKey = 'isCollapsed';

/// A [TreenodePath] references an [OutlineTreenode] in a document. It
/// consists of a series of integer, each referencing a child index, starting
/// with the children of the document's root node.
typedef TreenodePath = List<int>;

/// A [DocumentNodePath] is used to address a [DocumentNode] in an
/// [OutlineTreeDocument]. It consists of a `treenodePath`, only addressing
/// the [OutlineTreenode] that contains this DocumentNode] and then the
/// index of the [DocumentNode] in the treenode's `documentNodes` list.
class DocumentNodePath {
  DocumentNodePath(
    this.treenodePath,
    this.docNodeIndex,
  );

  TreenodePath treenodePath;
  int docNodeIndex;
}

/// Represents a treenode in the document structure. Each treenode contains
/// a `titleNode` and a list of `contentNodes` that point to [DocumentNodes]
/// that represent this one Treenode, and a list of other [OutlineTreenode]s
/// as children.
///
/// [OutlineTreenode]s will not persist as objects, but are
/// broken up into their [DocumentNode]s and added to the underlying
/// [MutableDocument]. This means that an [OutlineTreenode] should not
/// contain information apart from its contained documentNodeIds or references
/// to other tree nodes. To enforce this, this class is `final`.
final class OutlineTreenode /*extends ChangeNotifier */
    with
        Iterable<DocumentNode> {
  OutlineTreenode({
    TitleNode? titleNode,
    List<DocumentNode> contentNodes = const [],
    List<OutlineTreenode>? children,
    this.parent,
    bool isCollapsed = false,
    this.hasContentHidden = false,
    required this.id,
    required this.document,
    Map<String, dynamic>? metadata,
  }) : titleNode =
            titleNode ?? TitleNode(id: uuid.v4(), text: AttributedText('')) {
    // _titleNode =
    //     titleNode ?? TitleNode(id: uuid.v4(), text: AttributedText(''));
    _contentNodes.addAll(contentNodes);
    _metadata = metadata ?? {};
    if (children != null) {
      for (var child in children) {
        addChild(child);
      }
    }
    _isCollapsed = isCollapsed;
  }

  TitleNode titleNode;
  final List<DocumentNode> _contentNodes = [];
  final List<OutlineTreenode> _children = [];

  /// This [OutlineTreenode]'s parent; passing this in the constructor does
  /// not automatically add this node to the parent's `children` list.
  OutlineTreenode? parent;

  /// A unique identifier for this OutlineTreenode. Addressing OutlineTreenodes
  /// by path will usually be faster.
  final String id;

  /// The OutlineTreeDocument containing this node; this is needed to be able
  /// to eg. calculate ranges and similar, which needs knowledge only the
  /// document (or rather, SuperEditor's MutableDocument) has.
  final Document document;
  bool _isCollapsed = false;
  bool hasContentHidden = false;
  late Map<String, dynamic> _metadata;

// TODO: test
  void traverseUpDown(void Function(OutlineTreenode) visitor) {
    visitor(this);
    for (var child in _children) {
      child.traverseUpDown(visitor);
    }
  }

// TODO: test
  void traverseDownUp(void Function(OutlineTreenode) visitor) {
    for (var child in _children) {
      child.traverseDownUp(visitor);
    }
    visitor(this);
  }

  bool get isConsideredEmpty =>
      nodes.every((n) => n is TextNode && n.text.toPlainText().isEmpty) &&
      titleNode.text.toPlainText().isEmpty;

  bool hasMetadataValue(String key) => _metadata[key] != null;

  dynamic getMetadataValue(String key) => _metadata[key];

  void putMetadataValue(String key, dynamic value) {
    if (_metadata[key] == value) {
      return;
    }

    _metadata[key] = value;
    // notifyListeners();
  }

  void removeMetadataValue(String key) {
    _metadata.remove(key);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineTreenode &&
          id == other.id &&
          parent == other.parent &&
          document == other.document &&
          titleNode == other.titleNode &&
          const DeepCollectionEquality()
              .equals(_contentNodes, other._contentNodes) &&
          const DeepCollectionEquality().equals(_children, other._children);

  @override
  int get hashCode =>
      _contentNodes.hashCode ^
      titleNode.hashCode ^
      _children.hashCode ^
      id.hashCode ^
      parent.hashCode ^
      document.hashCode;

  // TitleNode get titleNode => _titleNode;
  // set titleNode(TitleNode node) => _titleNode = node;

  List<DocumentNode> get contentNodes => _contentNodes;

  List<DocumentNode> get nodes => [titleNode, ..._contentNodes];

  List<DocumentNode> get nodesSubtree {
    return [
      titleNode,
      ..._contentNodes,
      ...nodesChildren,
    ];
  }

  List<DocumentNode> get nodesChildren =>
      [for (var child in _children) ...child.nodesSubtree];

  /// Returns the [TreenodePath] to this treenode, which is a List of int with
  /// the first element being the index of my first ancestor in the root node's
  /// children.
  TreenodePath get path {
    if (parent == null) {
      return [];
    }
    final ret = parent!.path;
    ret.add(parent!.children.indexOf(this));
    return [...parent!.path, childIndex];
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

  OutlineTreenode getLastOutlineTreenodeInSubtree() {
    if (children.isNotEmpty) {
      return children.last.getLastOutlineTreenodeInSubtree();
    } else {
      return this;
    }
  }

  /// Returns the [OutlineTreenode] with the given [DocumentNodePath], if there
  /// is one in this subtree, else null.
  DocumentNode? getDocumentNodeByPath(DocumentNodePath docNodePath) {
    if (docNodePath.treenodePath.isEmpty) {
      return nodes[docNodePath.docNodeIndex];
    }
    return _children[docNodePath.treenodePath.first].getDocumentNodeByPath(
      DocumentNodePath(
        docNodePath.treenodePath.sublist(1),
        docNodePath.docNodeIndex,
      ),
    );
  }

  /// Returns the [OutlineTreenode] corresponding to the given treenode id
  /// (not DocumentNode id), or null if it isn't found in this node's subtree.
  OutlineTreenode? getOutlineTreenodeById(String id) {
    if (id == this.id) {
      return this;
    }
    for (var child in _children) {
      final ret = child.getOutlineTreenodeById(id);
      if (ret != null) return ret;
    }
    return null;
  }

  DocumentNode? getDocumentNodeById(String docNodeId) {
    var ret = nodes.firstWhereOrNull((e) => e.id == docNodeId);
    if (ret != null) return ret;
    for (var child in _children) {
      ret = child.getDocumentNodeById(docNodeId);
      if (ret != null) return ret;
    }
    return null;
  }

  DocumentNodePath? getPathToDocumentNode(DocumentNode docNode) {
    final index = nodes.indexOf(docNode);
    if (index != -1) {
      return DocumentNodePath(path, index);
    }
    for (var i = 0; i < _children.length; i++) {
      final ret = _children[i].getPathToDocumentNode(docNode);
      if (ret != null) return ret;
    }
    return null;
  }

  /// Whether this Treenode is considered collapsed.
  bool get isCollapsed => _isCollapsed;

  /// Sets whether this Treenode is considered collapsed.
  set isCollapsed(bool isCollapsed) {
    outlineDocLog.fine('set isCollapsed to $isCollapsed');
    _isCollapsed = isCollapsed;
    // titleNode.putMetadataValue(isCollapsedKey, isCollapsed);
    // notifyListeners();
  }

  /// Whether this OutlineTreenode is actually supposed to be visible. This
  /// returns false if a collapsed ancestor exists.
  bool get isVisible {
    if (parent == null) return true;
    if (parent!.isCollapsed) {
      return false;
    }
    return parent!.isVisible;
  }

  /// Returns a list of the Treenodes representing children of this Treenode.
  List<OutlineTreenode> get children => UnmodifiableListView(_children);

  void addChild(OutlineTreenode child, [int index = -1]) {
    if (index >= 0) {
      _children.insert(index, child);
    } else {
      _children.add(child);
    }
    child.parent = this;
    // notifyListeners();
  }

  void removeChild(OutlineTreenode child) {
    _children.remove(child);
    child.parent = null;
    // notifyListeners();
  }

  /// Get the `TreenodePath` to the lowest OutlineTreenode (ie. deepest depth)
  /// that is direct ancestor of both `this` and `other`. This may be this or
  /// other itself.
  TreenodePath getLowestCommonAncestorPath(OutlineTreenode other) {
    final TreenodePath lowestAncestorPath = [];
    final myPath = [...path];
    final otherPath = [...other.path];
    for (int i = 0; i < min(myPath.length, otherPath.length); i++) {
      if (myPath[i] == otherPath[i]) {
        lowestAncestorPath.add(myPath[i]);
      } else {
        break;
      }
    }
    return lowestAncestorPath;
  }

  /// Whether this OutlineTreenode is a direct descendant of `other`.
  /// In the case of `other==this`, this method will return `false`.
  bool isDescendantOf(OutlineTreenode other) {
    if (parent == null) {
      return false;
    }
    return parent!.isDescendantOf(other);
  }

  /// Whether this OutlineTreenode is a direct ancestor of `other`.
  /// In the case of `other==this`, this method will return `false`.
  bool isAncestorOf(OutlineTreenode other) {
    for (final child in children) {
      if (child == other || child.isAncestorOf(other)) {
        return true;
      }
    }
    return false;
  }

  /// At which position in this treenode's or its children's documentNodes
  /// the DocumentNode with nodeId is located, ie. 0 for first position, 1 for the
  /// second, etc. Returns -1 if it does not find nodeId.
  /// This is mainly used for component building: For example, the first
  /// node in a treenodes content might be decorated with a button or similar.
  int getIndexInSubtree(String nodeId) {
    int index = nodes.indexOf(document.getNodeById(nodeId)!);
    if (index != -1) {
      return index;
    }
    for (var child in _children) {
      index = child.getIndexInSubtree(nodeId);
      if (index != -1) {
        return index;
      }
    }
    return -1;
  }

  /// The index this OutlineTreenode holds in its parent's list of children,
  /// or -1 if root.
  int get childIndex => parent == null ? -1 : parent!.children.indexOf(this);

  /// Returns the depth of this TreeNode, 0 meaning a root node.
  /// Implementation begins with -1 as we skip the internal 'logical root node'.
  int get depth => parent == null ? -1 : parent!.depth + 1;

  /// Returns the first document node in this tree node's whole
  /// subtree (including this node itself), iterating through all descendents
  /// if needed.
  DocumentNode? get firstDocumentNodeInSubtree {
    if (nodes.isNotEmpty) {
      return _contentNodes.first;
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
    return nodes.last;
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

  /// Returns the [OutlineTreenode] that will be presented last in this
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
  OutlineTreenode? getOutlineTreenodeByDocumentNodeId(String docNodeId) {
    if (nodes.where((e) => e.id == docNodeId).isNotEmpty) return this;

    for (var treeNode in children) {
      final childRet = treeNode.getOutlineTreenodeByDocumentNodeId(docNodeId);
      if (childRet != null) return childRet;
    }
    return null;
  }

  OutlineTreenode get outlineTreenodeBefore {
    if (parent == null) {
      throw Exception(
          'tried finding OutlineTreenode before root, this is not allowed');
    }
    if (childIndex == 0) {
      return parent!;
    }
    return parent!.children[childIndex - 1].getLastOutlineTreenodeInSubtree();
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

  /// Returns a flat list of all OutlineTreenodes in this subtree, in depth-first
  /// order of appearance in the document
  List<OutlineTreenode> get subtreeList {
    return [
      this,
      for (final child in children) ...child.subtreeList,
    ];
  }

  @override
  // we only use child nodes for iterating if this is the root node, as
  // having content in the root would lead to problems eg. when inserting later
  Iterator<DocumentNode> get iterator =>
      parent == null ? nodesChildren.iterator : nodesSubtree.iterator;

  /// Returns whether the subtree of this [OutlineTreenode] has
  /// equivalent content to the one in `other`.
  ///
  /// Content equivalency compares types of content nodes, and the content
  /// within them, like the text of a paragraph, but ignores node IDs and
  /// ignores the runtime type of the [Document], itself.
  bool hasEquivalentContent(OutlineTreenode other) {
    if (!titleNode.hasEquivalentContent(other.titleNode)) return false;
    if (contentNodes.length != other.contentNodes.length) {
      return false;
    }
    if (children.length != other.children.length) {
      return false;
    }
    for (int i = 0; i < nodes.length; i++) {
      if (!nodes[i].hasEquivalentContent(other.nodes[i])) {
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

  @override
  String toString() {
    final shortenedId = id.length > 6 ? '#${id.substring(0, 6)}' : '#$id';
    final shortenedTitle = titleNode.text.toPlainText().length > 13
        ? '"${titleNode.text.toPlainText().substring(0, 10)}..."'
        : '"${titleNode.text.toPlainText()}"';
    return '[OutlineTreenode $shortenedId $shortenedTitle ${contentNodes.length} content nodes, ${children.length} children]';
  }
}
