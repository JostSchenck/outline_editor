import 'dart:math';

import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/util/logging.dart';

class OutlineTreeDocument
    with OutlineDocument, Iterable<DocumentNode>
    implements MutableDocument {
  OutlineTreeDocument() {
    _root = OutlineTreenode(
      id: 'root',
      document: this,
      children: [],
    );
    rebuildStructure();
  }

  @override
  void dispose() {
    _listeners.clear();
  }

  @override
  OutlineTreenode get root => _root;
  late OutlineTreenode _root;

  final _listeners = <DocumentChangeListener>[];
  late final OutlineTreenode _latestNodeSnapshot;
  bool _didReset = false;

  @override
  int get nodeCount => toList().length;

  @override
  bool get isEmpty => _root.documentNodes.isEmpty && _root.children.isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  Iterator<DocumentNode> get iterator => _root.iterator;

  @override
  DocumentNode get first {
    final ret = _root.firstDocumentNodeInSubtree;
    if (ret == null) {
      throw Exception("first called in a document without any DocumentNodes");
    }
    return ret;
  }

  @override
  DocumentNode? get firstOrNull => _root.firstDocumentNodeInSubtree;

  @override
  DocumentNode? get lastOrNull => root.lastDocumentNodeInSubtree;

  @override
  DocumentNode firstWhere(bool Function(DocumentNode element) test,
          {DocumentNode Function()? orElse}) =>
      _root.firstWhere(test);

  @override
  void add(DocumentNode node) {
    _root.lastOutlineTreeNodeInSubtree.documentNodes.add(node);
  }

  @override
  void addListener(DocumentChangeListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(DocumentChangeListener listener) {
    _listeners.remove(listener);
  }

  // this is not efficient in a tree structure document
  @override
  void deleteNodeAt(int index) {
    // TODO: If we introduce some sort of map to optimize this class, this may be done efficiently
    outlineDocLog.warning('calling deleteNodeAt is not efficient in an '
        'outline document');
    final nodeList = toList();
    if (index < 0 || index >= nodeList.length) {
      outlineDocLog.warning('deleteNodeAt failed, index out of bounds');
      return;
    }
    final node = nodeList[index];
    final outlineNode = _root.getOutlineTreenodeForDocumentNodeId(node.id);
    // this can not be null as we actually found the DocumentNode, so there is an OutlineNode
    outlineNode!.documentNodes.remove(node);
  }

  @override
  bool deleteNode(DocumentNode node) {
    final outlineNode = _root.getOutlineTreenodeForDocumentNodeId(node.id);
    if (outlineNode == null) {
      outlineDocLog
          .warning('deleteNode: node ${node.id} not found in outline tree');
      return false;
    }
    return outlineNode.documentNodes.remove(node);
  }

  @override
  DocumentNode? getNextVisibleDocumentnode(DocumentPosition pos) {
    for (var i = getNodeIndexById(pos.nodeId); i < nodeCount; i++) {
      if (isVisible(elementAt(i).id)) {
        return elementAt(i);
      }
    }
    return null;
  }

  @override
  DocumentNode? getNode(DocumentPosition position) =>
      getNodeById(position.nodeId);

  @override
  DocumentNode? getNodeAt(int index) {
    final nodes = toList();
    if (index >= 0 && index < nodes.length) {
      return nodes[index];
    }
    return null;
  }

  @override
  DocumentNode? getNodeAfter(DocumentNode node) {
    final nodes = toList();
    final index = nodes.indexWhere((n) => n.id == node.id);
    return index >= 0 && index < nodes.length - 1 ? nodes[index + 1] : null;
  }

  @override
  DocumentNode? getNodeBefore(DocumentNode node) {
    final nodes = toList();
    final index = nodes.indexWhere((n) => n.id == node.id);
    return index >= 1 && index < nodes.length ? nodes[index - 1] : null;
  }

  @override
  DocumentNode? getNodeById(String nodeId) {
    return _root.getDocumentNodeById(nodeId);
  }

  @override
  @Deprecated('Use getNodeIndexById() instead')
  int getNodeIndex(DocumentNode node) => getNodeIndexById(node.id);

  @override
  int getNodeIndexById(String nodeId) {
    return toList().indexWhere((n) => n.id == nodeId);
  }

  @override
  List<DocumentNode> getNodesInside(
      DocumentPosition position1, DocumentPosition position2) {
    final index1 = getNodeIndexById(position1.nodeId);
    if (index1 == -1) {
      throw Exception('No such position in document: $position1');
    }
    final index2 = getNodeIndexById(position2.nodeId);
    if (index2 == -1) {
      throw Exception('No such position in document: $position2');
    }
    final from = min(index1, index2);
    final to = max(index1, index2);
    return toList().sublist(from, to + 1);
  }

  @override
  bool hasEquivalentContent(Document other) {
    if (other is OutlineDocument) {
      return root.hasEquivalentContent(other.root);
    }
    return other.hasEquivalentContent(this);
  }

  /// Inserts a node at an index position in the document. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineTreeDocument]
  /// forces us sometimes to decide between two [OutlineTreenode]s, when the
  /// given index position is right between two nodes.
  /// This method prefers to append the given node to an [OutlineTreeNode]
  /// before the position instead of prepending it to the node after it.
  /// Only in the special case of `index==0` it will prepend to the root node's
  /// first child.
  @override
  void insertNodeAt(
      int index,
      DocumentNode node,
      ) {
    if (index == 0) {
      if (_root.children.isEmpty) {
        _root.addChild(OutlineTreenode(
          id: uuid.v4(),
          document: this,
        ));
      }
      final treenode = _root.children.first;
      treenode.documentNodes.insert(0, node);
    }
  }

  /// Inserts a node right before a given existing node. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineTreeDocument]
  /// forces us sometimes to decide between two [OutlineTreenode]s, when the
  /// existing node is the last [DocumentNode] of an [OutlineTreenode].
  /// This method always assumes to stay in the same [OutlineTreenode]; ie. if
  /// existingNode is the first DocumentNode in a Treenode, newNode will be
  /// prepended to this Treenode, not inserted before the following.
  /// This can give unintended results if the first [DocumentNode], the `head`,
  /// has some special meaning. Care should be taken to avoid this; however,
  /// we can not choose a different behavior without breaking [Document]
  /// semantics, which we don't want.
  @override
  void insertNodeBefore(
      {required DocumentNode existingNode, required DocumentNode newNode}) {
    final pathToExistingNode = _root.getPathToDocumentNode(existingNode);
    if (pathToExistingNode == null || pathToExistingNode.treenodePath.isEmpty) {
      outlineDocLog.warning(
          'insertNodeBefore called on non-existing node $existingNode');
      return;
    }
    final treenode =
    _root.getOutlineTreenodeByPath(pathToExistingNode.treenodePath)!;
    treenode.documentNodes
        .insert(treenode.documentNodes.indexOf(existingNode), newNode);
  }

  /// Inserts a node right after a given existing node. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineTreeDocument]
  /// forces us sometimes to decide between two [OutlineTreenode]s, when the
  /// existing node is the last [DocumentNode] of an [OutlineTreenode].
  /// This method always assumes to stay in the same [OutlineTreenode]; ie. if
  /// existingNode is the last DocumentNode in a Treenode, newNode will be
  /// appended to this Treenode, not inserted before the following.
  @override
  void insertNodeAfter({
    required DocumentNode existingNode,
    required DocumentNode newNode,
  }) {
    final pathToExistingNode = _root.getPathToDocumentNode(existingNode);
    if (pathToExistingNode == null || pathToExistingNode.treenodePath.isEmpty) {
      outlineDocLog
          .warning('insertNodeAfter called on non-existing node $existingNode');
      return;
    }
    final treenode =
        _root.getOutlineTreenodeByPath(pathToExistingNode.treenodePath)!;
    treenode.documentNodes
        .insert(treenode.documentNodes.indexOf(existingNode) + 1, newNode);
  }

      @override
  bool isCollapsed(String treeNodeId) =>
      getOutlineTreenodeForDocumentNodeId(treeNodeId).isCollapsed;

  @override
  void setCollapsed(String treeNodeId, bool isCollapsed) {
    getOutlineTreenodeForDocumentNodeId(treeNodeId).isCollapsed = isCollapsed;
  }

  @override
  bool isHidden(String documentNodeId) =>
      getNodeById(documentNodeId)!.getMetadataValue(isHiddenKey) == true;

  @override
  void setHidden(String documentNodeId, bool isHidden) {
    getNodeById(documentNodeId)!.putMetadataValue(isHiddenKey, isHidden);
  }

  @override
  void moveNode({required String nodeId, required int targetIndex}) {
    final node = _root.getDocumentNodeById(nodeId);
    if (node == null) {
      outlineDocLog.warning('moveNode called on non-existing node $nodeId');
      return;
    }
    final nodePath = _root.getPathToDocumentNode(node);
    final outlineNode = _root.getOutlineTreenodeByPath(nodePath!.treenodePath)!;
    outlineNode.documentNodes.remove(node);
    insertNodeAt(targetIndex, node);
  }

  @override
  void replaceNode(
      {required DocumentNode oldNode, required DocumentNode newNode}) {
    final nodePath = _root.getPathToDocumentNode(oldNode);
    if (nodePath == null || nodePath.treenodePath.isEmpty) {
      outlineDocLog.warning('replaceNode called on non-existing node $oldNode');
      return;
    }
    final outlineNode = _root.getOutlineTreenodeByPath(nodePath.treenodePath)!;
    outlineNode.documentNodes.remove(oldNode);
    outlineNode.documentNodes.insert(nodePath.docNodeIndex, newNode);
  }

  @override
  void onTransactionEnd(List<EditEvent> edits) {
    final documentChanges = edits.whereType<DocumentEdit>().map((edit) => edit.change).toList();
    if (documentChanges.isEmpty && !_didReset) {
      return;
    }
    _didReset = false;

    final changeLog = DocumentChangeLog(documentChanges);
    for (final listener in _listeners) {
      listener(changeLog);
    }
  }

  @override
  void onTransactionStart() {
    // TODO: implement onTransactionStart
  }

  @override
  void rebuildStructure() {
    // do nothing here, as our tree structure is already our
    // single source of truth
  }

  @override
  void reset() {
    // TODO: implement reset
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is OutlineTreeDocument
    && runtimeType == other.runtimeType
    && _root == other.root;

  @override
  int get hashCode => _root.hashCode;
}
