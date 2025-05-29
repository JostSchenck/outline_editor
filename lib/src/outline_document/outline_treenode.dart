import 'package:collection/collection.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

const isCollapsedKey = 'isCollapsed';

/// A [TreenodePath] references an [OutlineTreenode] in a document. It
/// consists of a series of integer, each referencing a child index, starting
/// with the children of the document's root node.
typedef TreenodePath = List<int>;

/// A [DocumentNodePath] is used to address a [DocumentNode] in an
/// [OutlineEditableDocument]. It consists of a `treenodePath`, only addressing
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
abstract class OutlineTreenode<
        T extends OutlineTreenode<T>> /*extends ChangeNotifier */
    with
        Iterable<DocumentNode> {
  final TitleNode titleNode;
  final UnmodifiableListView<DocumentNode> contentNodes;
  final UnmodifiableListView<T> children;

  /// A unique identifier for this OutlineTreenode. Addressing OutlineTreenodes
  /// by path will usually be faster.
  final String id;

  final bool isCollapsed;
  final bool hasContentHidden;
  late UnmodifiableMapView<String, dynamic> metadata;

  OutlineTreenode({
    required this.id,
    required this.titleNode,
    final List<DocumentNode>? contentNodes,
    final List<T>? children,
    this.isCollapsed = false,
    this.hasContentHidden = false,
    Map<String, dynamic>? metadata,
  })  : contentNodes = UnmodifiableListView(contentNodes ?? []),
        children = UnmodifiableListView(children ?? []),
        metadata = UnmodifiableMapView(metadata ?? {});

  /// Returns a copy of this treenode, with optional replacements. This copy is
  /// deep in the sense that the whole tree of OutlineTreenode's is copied.
  /// If also DocumentNodes should be deeply copied, use copyWithDeep.
  T copyWith({
    String? id,
    TitleNode? titleNode,
    List<DocumentNode>? contentNodes,
    List<T>? children,
    bool? isCollapsed,
    bool? hasContentHidden,
    Map<String, dynamic>? metadata,
  });

  /// Fügt ein neues Kind an gegebener Stelle ein (oder am Ende, wenn kein Index angegeben).
  T copyInsertChild({
    required T child,
    int? atIndex,
  }) {
    final newChildren = [...children];
    final index = atIndex ?? newChildren.length;
    return copyWith(
      children: [
        ...newChildren.sublist(0, index),
        child,
        ...newChildren.sublist(index),
      ],
    );
  }

  /// Entfernt ein Kind per ID und gibt Kopie zurück
  T copyRemoveChild({
    required String childId,
  }) {
    final newChildren = children.where((c) => c.id != childId).toList();
    return copyWith(children: newChildren);
  }

  /// Entfernt einen content node per ID
  T copyRemoveContentNode({
    required String docNodeId,
  }) {
    final newContentNodes =
        contentNodes.where((c) => c.id != docNodeId).toList();
    return copyWith(contentNodes: newContentNodes);
  }

  /// Replaces a DocumentNode in contentNodes by id
  T copyReplaceContentNodeInTreenode({required DocumentNode replaceNode}) {
    final index = contentNodes.indexWhere((n) => n.id == replaceNode.id);
    if (index == -1) {
      throw Exception(
          'copyReplaceContentNodeInTreenode, but content node not found in treenode');
    }
    final updatedContent = [...contentNodes];
    updatedContent[index] = replaceNode;
    return copyWith(contentNodes: updatedContent);
  }

  /// Fügt oder ändert einen Metadata-Eintrag
  T copySetMetadataValue(
    String key,
    dynamic value,
  ) {
    final newMetadata = {...metadata, key: value};
    return copyWith(metadata: newMetadata);
  }

  /// Entfernt einen Metadata-Eintrag
  T copyRemoveMetadataValue(
    String key,
  ) {
    final newMetadata = {...metadata}..remove(key);
    return copyWith(metadata: newMetadata);
  }

  /// Fügt einen neuen DocumentNode an gegebener Stelle in den contentNodes
  /// dieses treenodes ein (oder am Ende, wenn kein Index angegeben).
  T copyInsertDocumentNode({
    required DocumentNode docNode,
    int? atIndex,
  }) {
    assert(docNode is! TitleNode);
    final index = atIndex ?? contentNodes.length;
    return copyWith(
      contentNodes: [
        ...contentNodes.sublist(0, index),
        docNode,
        ...contentNodes.sublist(index),
      ],
    );
  }

  /// Returns a full deep copy of this treenode and all its contents
  T copyWithDeep({
    String? id,
    TitleNode? titleNode,
    List<DocumentNode>? contentNodes,
    List<T>? children,
    bool? isCollapsed,
    bool? hasContentHidden,
    Map<String, dynamic>? metadata,
  });

  /// Traverses the tree and replaces a node by id using the given transformer function.
  T replaceTreenodeById(String targetId, T Function(T p) transform) {
    if (id == targetId) {
      return transform(this as T);
    }
    return copyWith(
      children: children
          .map((c) => c.replaceTreenodeById(targetId, transform))
          .toList(),
    );
  }

  /// Deletes the treenode with the given [targetId] from the tree.
  /// Returns the updated root treenode, or `this` if not found or root is target.
  T removeTreenode(String targetId) {
    // Sonderfall: aktuelle Wurzel soll gelöscht werden – nicht erlaubt
    if (id == targetId) return this as T;

    // Falls Kind direkt getroffen: entfernen
    final updatedChildren = children.where((c) => c.id != targetId).toList();
    if (updatedChildren.length != children.length) {
      return copyWith(children: updatedChildren);
    }

    // Sonst rekursiv in den Unterbäumen weiter suchen
    return copyWith(
      children: children.map((c) => c.removeTreenode(targetId)).toList(),
    );
  }

  /// Searches for a node by id
  T? getTreenodeById(String targetId) {
    if (id == targetId) return this as T;
    for (final child in children) {
      final result = child.getTreenodeById(targetId);
      if (result != null) return result;
    }
    return null;
  }

  /// Returns the parent of the node with [targetId], if any
  T? getParentOf(String targetId) {
    for (final child in children) {
      if (child.id == targetId) return this as T;
      final result = child.getParentOf(targetId);
      if (result != null) return result;
    }
    return null;
  }

  /// Returns the path (list of child indices) to the treenode with [treenodeId], or null if not found
  TreenodePath? getPathTo(String treenodeId) {
    if (id == treenodeId) return [];
    for (int i = 0; i < children.length; i++) {
      final pathFromChild = children[i].getPathTo(treenodeId);
      if (pathFromChild != null) {
        return [i, ...pathFromChild];
      }
    }
    return null;
  }

  /// Getss the node at the given path, or null if invalid
  T? getTreenodeByPath(TreenodePath path) {
    if (path.isEmpty) return this as T;
    final index = path.first;
    if (index < 0 || index >= children.length) return null;
    return children[index].getTreenodeByPath(path.sublist(1));
  }

  /// Returns the list of ancestor nodes (from root to parent of target), or null if not found
  List<T>? getAncestorsOf(String targetId) {
    if (id == targetId) return [];
    for (final child in children) {
      final subAncestors = child.getAncestorsOf(targetId);
      if (subAncestors != null) {
        return [this as T, ...subAncestors];
      }
    }
    return null;
  }

  /// Returns both the node with the given id and its path, or null if not found
  ({T treenode, TreenodePath path})? getTreenodeAndPathById(String targetId) {
    if (id == targetId) return (treenode: this as T, path: []);
    for (int i = 0; i < children.length; i++) {
      final result = children[i].getTreenodeAndPathById(targetId);
      if (result != null) {
        return (treenode: result.treenode, path: [i, ...result.path]);
      }
    }
    return null;
  }

  /// Returns both the treenode that contains [docNode], and its path, or null if not found
  ({T treenode, TreenodePath path})? getTreenodeContainingDocumentNode(
      String docNodeId) {
    if (titleNode.id == docNodeId ||
        contentNodes.any((n) => n.id == docNodeId)) {
      return (treenode: this as T, path: []);
    }
    for (int i = 0; i < children.length; i++) {
      final result = children[i].getTreenodeContainingDocumentNode(docNodeId);
      if (result != null) {
        return (treenode: result.treenode, path: [i, ...result.path]);
      }
    }
    return null;
  }

  /// Returns both the treenode that contains [docNode], and its path, or null if not found
  DocumentNodePath? getDocumentNodePathById(String docNodeId) {
    final index = nodes.indexWhere((element) => element.id == docNodeId);
    if (index != -1) return DocumentNodePath([], index);
    for (int i = 0; i < children.length; i++) {
      final result = children[i].getDocumentNodePathById(docNodeId);
      if (result != null) {
        return DocumentNodePath(
            [i, ...result.treenodePath], result.docNodeIndex);
      }
    }
    return null;
  }

  /// Returns a flat list of all nodes in this subtree (depth-first)
  List<T> get subtreeList {
    return [
      this as T,
      for (final child in children) ...child.subtreeList,
    ];
  }

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  // @override
  // bool operator ==(Object other) =>
  //     identical(this, other) ||
  //     other is OutlineTreenode &&
  //         id == other.id &&
  //         titleNode == other.titleNode &&
  //         _listEquals(contentNodes, other.contentNodes) &&
  //         _listEquals(children, other.children) &&
  //         isCollapsed == other.isCollapsed &&
  //         hasContentHidden == other.hasContentHidden &&
  //         _mapEquals(metadata, other.metadata);
  //
  // @override
  // int get hashCode =>
  //     id.hashCode ^
  //     titleNode.hashCode ^
  //     contentNodes.hashCode ^
  //     children.hashCode ^
  //     isCollapsed.hashCode ^
  //     hasContentHidden.hashCode ^
  //     metadata.hashCode;
  //
  // static bool _listEquals<T>(List<T> a, List<T> b) {
  //   if (a.length != b.length) return false;
  //   for (int i = 0; i < a.length; i++) {
  //     if (a[i] != b[i]) return false;
  //   }
  //   return true;
  // }
  //
  // static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  //   if (a.length != b.length) return false;
  //   for (final key in a.keys) {
  //     if (!b.containsKey(key) || a[key] != b[key]) return false;
  //   }
  //   return true;
  // }

  @override
  String toString() {
    final shortenedId = id.length > 6 ? '#${id.substring(0, 6)}' : '#$id';
    final shortenedTitle = titleNode.text.toPlainText().length > 13
        ? '"${titleNode.text.toPlainText().substring(0, 10)}..."'
        : '"${titleNode.text.toPlainText()}"';
    return '[OutlineTreenode $shortenedId $shortenedTitle ${contentNodes.length} content nodes, ${children.length} children]';
  }

  List<DocumentNode> get nodes => [titleNode, ...contentNodes];

  void traverseUpDown(void Function(T treenode) visitor) {
    visitor(this as T);
    for (var child in children) {
      child.traverseUpDown(visitor);
    }
  }

  /// Does an up down traversion of the tree where the visiting of all
  /// children is awaited for before the parent is visited. Also, between
  /// children is awaited.
  Future<void> traverseUpDownAsync(
      Future<void> Function(T treenode) visitor) async {
    visitor(this as T).then((value) async {
      for (var child in children) {
        await child.traverseUpDownAsync(visitor);
      }
    });
  }

  void traverseDownUp(void Function(T treenode) visitor) {
    for (var child in children) {
      child.traverseDownUp(visitor);
    }
    visitor(this as T);
  }

  /// Does an down up traversion of the tree where the visiting of all
  /// children is awaited for before the parent is visited.
  Future<void> traverseDownUpAsync(
      Future<void> Function(T treenode) visitor) async {
    final futures =
        children.map((c) => c.traverseDownUpAsync(visitor)).toList();
    await Future.wait(futures);
    visitor(this as T);
  }

  bool get isConsideredEmpty =>
      nodes.every((n) => n is TextNode && n.text.toPlainText().isEmpty);

  bool hasMetadataValue(String key) => metadata[key] != null;

  // void putMetadataValue(String key, dynamic value) {
  //   if (_metadata[key] == value) {
  //     return;
  //   }
  //
  //   _metadata[key] = value;
  //   // notifyListeners();
  // }
  //
  // void removeMetadataValue(String key) {
  //   _metadata.remove(key);
  // }

  List<DocumentNode> get nodesSubtree {
    return [
      titleNode,
      ...contentNodes,
      ...nodesChildren,
    ];
  }

  List<DocumentNode> get nodesChildren =>
      [for (var child in children) ...child.nodesSubtree];

  // /// Returns the [TreenodePath] to this treenode, which is a List of int with
  // /// the first element being the index of my first ancestor in the root node's
  // /// children.
  // TreenodePath get path {
  //   if (parent == null) {
  //     return [];
  //   }
  //   final ret = parent!.path;
  //   ret.add(parent!.children.indexOf(this));
  //   return [...parent!.path, childIndex];
  // }

  // /// Returns the [OutlineTreenode] with the given [TreenodePath], if there
  // /// is such a descendent, else null.
  // OutlineTreenode? getOutlineTreenodeByPath(TreenodePath path) {
  //   if (path.isEmpty) {
  //     return null;
  //   }
  //   if (path.length == 1) {
  //     return _children[path.first];
  //   }
  //   return _children[path.first].getOutlineTreenodeByPath(path.sublist(1));
  // }

  T getLastOutlineTreenodeInSubtree() {
    if (children.isNotEmpty) {
      return children.last.getLastOutlineTreenodeInSubtree();
    } else {
      return this as T;
    }
  }

  /// Returns the [DocumentNode] with the given [DocumentNodePath], if there
  /// is one in this subtree, else null.
  DocumentNode? getDocumentNodeByPath(DocumentNodePath docNodePath) {
    if (docNodePath.treenodePath.isEmpty) {
      return nodes[docNodePath.docNodeIndex];
    }
    return children[docNodePath.treenodePath.first].getDocumentNodeByPath(
      DocumentNodePath(
        docNodePath.treenodePath.sublist(1),
        docNodePath.docNodeIndex,
      ),
    );
  }

  // /// Returns the [OutlineTreenode] corresponding to the given treenode id
  // /// (not DocumentNode id), or null if it isn't found in this node's subtree.
  // OutlineTreenode? getOutlineTreenodeById(String id) {
  //   if (id == this.id) {
  //     return this;
  //   }
  //   for (var child in _children) {
  //     final ret = child.getOutlineTreenodeById(id);
  //     if (ret != null) return ret;
  //   }
  //   return null;
  // }

  /// Traverses this treenode's subtree up down, returning the first treenode
  /// which satisfies `testFunction` or null.
  T? getFirstTreenodeWhereOrNull(bool Function(T treenode) testFunction) {
    if (testFunction(this as T)) return this as T;
    for (var child in children) {
      final subtreeResult = child.getFirstTreenodeWhereOrNull(testFunction);
      if (subtreeResult != null) return subtreeResult;
    }
    return null;
  }

  bool isDescendant(T treenode) {
    return getFirstTreenodeWhereOrNull((tn) => tn.id == treenode.id) != null;
  }

  DocumentNode? getDocumentNodeById(String docNodeId) {
    var ret = nodes.firstWhereOrNull((e) => e.id == docNodeId);
    if (ret != null) return ret;
    for (var child in children) {
      ret = child.getDocumentNodeById(docNodeId);
      if (ret != null) return ret;
    }
    return null;
  }

  // DocumentNodePath? getPathToDocumentNode(DocumentNode docNode) {
  //   final index = nodes.indexOf(docNode);
  //   if (index != -1) {
  //     return DocumentNodePath(path, index);
  //   }
  //   for (var i = 0; i < _children.length; i++) {
  //     final ret = _children[i].getPathToDocumentNode(docNode);
  //     if (ret != null) return ret;
  //   }
  //   return null;
  // }

  /// Whether the descendent OutlineTreenode with `id` is actually supposed to
  /// be visible. This returns false if a collapsed ancestor exists.
  bool isTreenodeVisible(String treenodeId) {
    final ancestors = getAncestorsOf(treenodeId);
    if (ancestors == null) {
      throw Exception(
          'isTreenodeVisible called on id that does not exist in this tree');
    }
    if (ancestors.isEmpty) return true;
    if (ancestors.reversed.any((element) => element.isCollapsed)) return false;
    return true;
  }

  /// Whether the descendent OutlineTreenode in `path` is actually supposed to
  /// be visible. This returns false if a collapsed ancestor exists.
  bool isTreenodeVisibleByPath(TreenodePath path) {
    if (path.isEmpty) return true;
    // as path is not empty, it signifies a descendent of this node, so its
    // visibility is false, if this node is collapsed:
    if (isCollapsed) return false;
    if (children.isEmpty) {
      outlineDocLog.shout('local path not empty, but no children?');
    }
    return (children[path.first].isTreenodeVisibleByPath(path.sublist(1)));
  }

  /// Whether the descendent DocumentNode with `id` is actually supposed to
  /// be visible. This returns false if the corresponding treenode's content
  /// is hidden or a collapsed ancestor exists for the corresponding treenode.
  bool isDocumentNodeVisible(String docNodeId) {
    final result = getTreenodeContainingDocumentNode(docNodeId);
    if (result == null) {
      throw Exception(
          'isDocumentNodeVisible called on id that does not exist in this tree');
    }
    final docNodePath = getDocumentNodePathById(docNodeId);
    // Hide DocumentNodes if content is supposed to be hidden, of if the
    // treenode is collapsed; don't hide the title node:
    if (docNodePath!.docNodeIndex != 0 &&
        (result.treenode.isCollapsed || result.treenode.hasContentHidden)) {
      return false;
    }
    return isTreenodeVisibleByPath(result.path);
  }

  // /// Get the `TreenodePath` to the lowest OutlineTreenode (ie. deepest depth)
  // /// that is direct ancestor of both `this` and `other`. This may be this or
  // /// other itself.
  // TreenodePath getLowestCommonAncestorPath(OutlineTreenode other) {
  //   final TreenodePath lowestAncestorPath = [];
  //   final myPath = [...path];
  //   final otherPath = [...other.path];
  //   for (int i = 0; i < min(myPath.length, otherPath.length); i++) {
  //     if (myPath[i] == otherPath[i]) {
  //       lowestAncestorPath.add(myPath[i]);
  //     } else {
  //       break;
  //     }
  //   }
  //   return lowestAncestorPath;
  // }

  // /// Whether this OutlineTreenode is a direct descendant of `other`.
  // /// In the case of `other==this`, this method will return `false`.
  // bool isDescendantOf(OutlineTreenode other) {
  //   if (parent == null) {
  //     return false;
  //   }
  //   return parent!.isDescendantOf(other);
  // }

  // /// Whether this OutlineTreenode is a direct ancestor of `other`.
  // /// In the case of `other==this`, this method will return `false`.
  // bool isAncestorOf(OutlineTreenode other) {
  //   for (final child in children) {
  //     if (child == other || child.isAncestorOf(other)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  // /// The index this OutlineTreenode holds in its parent's list of children,
  // /// or -1 if root.
  // int get childIndex => parent == null ? -1 : parent!.children.indexOf(this);
  //
  // /// Returns the depth of this TreeNode, 0 meaning a root node.
  // /// Implementation begins with -1 as we skip the internal 'logical root node'.
  // int get depth => parent == null ? -1 : parent!.depth + 1;

  /// Returns the first document node in this tree node's whole
  /// subtree (including this node itself), iterating through all descendents
  /// if needed.
  DocumentNode? get firstDocumentNodeInSubtree {
    if (nodes.isNotEmpty) {
      return nodes.first;
    }
    return firstDocumentNodeInChildren;
  }

  /// Returns the first document node in this tree node's child nodes,
  /// iterating through all descendents if needed.
  DocumentNode? get firstDocumentNodeInChildren {
    for (var child in children) {
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
    if (children.isNotEmpty) {
      return lastDocumentNodeInChildren;
    }
    return nodes.last;
  }

  /// Returns the last document node in this tree node's child nodes,
  /// iterating through all descendents if needed.
  DocumentNode? get lastDocumentNodeInChildren {
    if (children.isEmpty) return null;
    for (var child in children.reversed) {
      final returnNode = child.lastDocumentNodeInSubtree;
      if (returnNode != null) {
        return returnNode;
      }
    }
    return null;
  }

  /// Returns the [OutlineTreenode] that will be presented last in this
  /// node's whole subtree.
  T get lastTreenodeInSubtree {
    if (children.isNotEmpty) {
      return children.last.lastTreenodeInSubtree;
    }
    return this as T;
  }

  /// Searches this [OutlineTreenode]'s whole subtree and returns
  /// the [OutlineTreenode] that holds the given id to a
  /// [DocumentNode].
  T? getTreenodeByDocumentNodeId(String docNodeId) {
    if (nodes.where((e) => e.id == docNodeId).isNotEmpty) return this as T;

    for (var treeNode in children) {
      final childRet = treeNode.getTreenodeByDocumentNodeId(docNodeId);
      if (childRet != null) return childRet;
    }
    return null;
  }

  // OutlineTreenode get outlineTreenodeBefore {
  //   if (parent == null) {
  //     throw Exception(
  //         'tried finding OutlineTreenode before root, this is not allowed');
  //   }
  //   if (childIndex == 0) {
  //     return parent!;
  //   }
  //   return parent!.children[childIndex - 1].getLastOutlineTreenodeInSubtree();
  // }

  /// Moves a treenode at [fromPath] into [toPath], inserting it at [insertIndex] in the children list.
  /// Returns the updated root treenode.
  T moveTreenode({
    required TreenodePath fromPath,
    required TreenodePath toPath,
    required int insertIndex,
  }) {
    final movingTreenode = getTreenodeByPath(fromPath);
    if (movingTreenode == null) return this as T;

    final rootWithoutSource = removeTreenodeAtPath(fromPath);
    final targetParent = rootWithoutSource.getTreenodeByPath(toPath);
    if (targetParent == null) return this as T;

    final newChildren = [...targetParent.children];
    newChildren.insert(insertIndex, movingTreenode);

    final updatedTarget = targetParent.copyWith(children: newChildren);
    return rootWithoutSource.replaceTreenodeById(
        updatedTarget.id, (_) => updatedTarget);
  }

  T removeTreenodeAtPath(TreenodePath path) {
    if (path.isEmpty) return this as T;
    final indexToRemove = path.first;
    if (path.length == 1) {
      final updatedChildren = [...children]..removeAt(indexToRemove);
      return copyWith(children: updatedChildren);
    } else {
      final child = children[indexToRemove];
      final updatedChild = child.removeTreenodeAtPath(path.sublist(1));
      final updatedChildren = [...children];
      updatedChildren[indexToRemove] = updatedChild;
      return copyWith(children: updatedChildren);
    }
  }

  @override
  Iterator<DocumentNode> get iterator => nodesSubtree.iterator;

  /// Returns whether the subtree of this [OutlineTreenode] has
  /// equivalent content to the one in `other`.
  ///
  /// Content equivalency compares types of content nodes, and the content
  /// within them, like the text of a paragraph, but ignores node IDs and
  /// ignores the runtime type of the [Document], itself.
  bool hasEquivalentContent(T other) {
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
}
