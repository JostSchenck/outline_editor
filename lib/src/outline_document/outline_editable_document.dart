import 'dart:math';

import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/util/logging.dart';

typedef TreenodeBuilder = OutlineTreenode Function({
  String? id,
  TitleNode? titleNode,
  List<DocumentNode>? contentNodes,
});

class OutlineEditableDocument<T extends OutlineTreenode<T>>
    with OutlineDocument<T>, Iterable<DocumentNode>
    implements MutableDocument {
  OutlineEditableDocument({
    required this.treenodeBuilder,
    T? logicalRoot,
    List<T>? rootTreeNodes,
  }) : // we take care that the logical root is empty, so that insertion logic works later
        _root = logicalRoot != null
            ? logicalRoot.copyWith(titleNode: null, contentNodes: [])
            : treenodeBuilder(id: 'root')
                .copyWith(titleNode: null, contentNodes: []) as T {
    _resetRoot = root.copyWith();
  }

  /// Constructs an OutlineEditableDocument with only an empty treenode with
  /// an empty title node and one empty paragraph.
  factory OutlineEditableDocument.empty({
    String? treenodeId,
    String? titleNodeId,
    String? paragraphNodeId,
    TreenodeBuilder? treenodeBuilder,
  }) {
    final myTreenodeBuilder = treenodeBuilder ?? basicOutlineTreenodeBuilder;
    final doc = OutlineEditableDocument<T>(
        treenodeBuilder: myTreenodeBuilder,
        logicalRoot: myTreenodeBuilder(id: 'root').copyWith(children: [
          myTreenodeBuilder(
              id: treenodeId ?? uuid.v4(),
              titleNode: TitleNode(
                  id: titleNodeId ?? uuid.v4(), text: AttributedText('')),
              contentNodes: [
                ParagraphNode(
                    id: paragraphNodeId ?? uuid.v4(), text: AttributedText('')),
              ])
        ]) as T);
    return doc;
  }

  final TreenodeBuilder treenodeBuilder;

  @override
  void dispose() {
    _listeners.clear();
  }

  @override
  T get root => _root;

  set root(T value) {
    _root = value;
    // _latestNodeSnapshot = value;
    // _didReset = true;
    // _notifyListeners();
  }

  late T _root;
  late T _resetRoot;

  final _listeners = <DocumentChangeListener>[];
  late final T _latestNodeSnapshot;
  bool _didReset = false;

  @override
  int get nodeCount => toList().length;

  @override
  bool get isEmpty => _root.nodes.isEmpty && _root.children.isEmpty;

  @override
  bool get isNotEmpty => !isEmpty;

  /// The iterator for an OutlineEditableDocument does not iterate over the
  /// 'logical root node' but only over all children; this way, we have a
  /// single root internally (not visible to end user), while users can create
  /// more than one root node.
  @override
  Iterator<DocumentNode> get iterator => _root.nodesChildren.iterator;

  @override
  DocumentNode get first {
    final ret = _root.firstDocumentNodeInChildren;
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
    root = _root.replaceTreenodeById(_root.lastTreenodeInSubtree.id,
        (p) => p.copyWith(contentNodes: [...p.contentNodes, node]));
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
    outlineDocLog.warning('calling deleteNodeAt is not efficient in an '
        'outline document');
    final nodeList = toList();
    if (index < 0 || index >= nodeList.length) {
      outlineDocLog.warning('deleteNodeAt failed, index out of bounds');
      return;
    }
    deleteNode(nodeList[index].id);
  }

  @override
  bool deleteNode(String nodeId) {
    final outlineNode = _root.getTreenodeByDocumentNodeId(nodeId);
    if (outlineNode == null) {
      outlineDocLog
          .warning('deleteNode: node $nodeId not found in outline tree');
      return false;
    }
    root = _root.replaceTreenodeById(
      outlineNode.id,
      (p) => p.copyRemoveContentNode(docNodeId: nodeId),
    );
    return true;
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
    if (other is OutlineEditableDocument<T>) {
      return root.hasEquivalentContent(other.root);
    }
    return other.hasEquivalentContent(this);
  }

  /// Inserts a node at an index position in the document. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineEditableDocument]
  /// forces us sometimes to decide between two [OutlineTreenode]s, when the
  /// given index position is right between two nodes.
  /// This method prefers to append the given node to an [OutlineTreeNode]
  /// before the position instead of prepending it to the node after it.
  /// Only in the special case of `index==0` it will prepend to the root node
  /// to a new treenode.
  // TODO: TEST!!!
  @override
  void insertNodeAt(
    int index,
    DocumentNode node,
  ) {
    if (node is TitleNode) {
      throw Exception('A TitleNode must not be inserted using insertNodeXXX'
          ' methods; instead, a Treenode must be inserted explicitly');
    }
    if (index == 0) {
      // The node is to be inserted at the start of the document before the
      // first node. This is illegal in an OutlineEditableDocument, because we can't
      // insert something in the same OutlineTreenode before the TitleNode.
      throw Exception('insertNodeAt tried to insert a DocumentNode before '
          'the first OutlineTreenode');
    }
    if (index == length) {
      // Node is appended at the end of the document. Easy:
      final lastTreenode = _root.getLastOutlineTreenodeInSubtree();
      root = _root.replaceTreenodeById(
          lastTreenode.id,
          (_) => lastTreenode
              .copyWith(contentNodes: [...lastTreenode.contentNodes, node]));
      return;
    }
    // it's somewhere inbetween:
    // first find the DocumentNode at index, to which our new node should be
    // prepended (sensibly with an eye on outline structure):
    final existingNode = getNodeAt(index);
    if (existingNode == null) {
      outlineDocLog.warning(
          'Tried inserting at illegal position $index, where no node was found');
      return;
    }
    final docNodePath = _root.getDocumentNodePathById(existingNode.id);
    final path = docNodePath!.treenodePath;
    final treenode = getTreenodeByPath(path);
    if (existingNode is TitleNode) {
      // A TitleNode is always the first DocumentNode in an OutlineTreenode.
      // This means we can not add to treenode, but must prepend to it.
      final treenodeBefore = getTreenodeBeforeTreenode(treenode.id);
      root = _root.replaceTreenodeById(treenodeBefore!.id,
          (p) => p.copyWith(contentNodes: [...p.contentNodes, node]));
      return;
    }
    // okay, index pointed to a simple content node:
    // minus 1, as a 0 path always points to the title node
    final cnIndex = index - getNodeIndexById(treenode.titleNode.id) - 1;
    root = _root.replaceTreenodeById(treenode.id,
        (p) => p.copyInsertDocumentNode(docNode: node, atIndex: cnIndex));
  }

  /// Inserts a node right before a given existing node. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineEditableDocument]
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
      {required String existingNodeId, required DocumentNode newNode}) {
    insertNodeAt(getNodeIndexById(existingNodeId), newNode);
  }

  /// Inserts a node right after a given existing node. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineEditableDocument]
  /// forces us sometimes to decide between two [OutlineTreenode]s, when the
  /// existing node is the last [DocumentNode] of an [OutlineTreenode].
  /// This method always assumes to stay in the same [OutlineTreenode]; ie. if
  /// existingNode is the last DocumentNode in a Treenode, newNode will be
  /// appended to this Treenode, not inserted before the following.
  /// TitleNodes must not be inserted with this method.
  @override
  void insertNodeAfter({
    required String existingNodeId,
    required DocumentNode newNode,
  }) {
    insertNodeAt(getNodeIndexById(existingNodeId) + 1, newNode);
  }

  @override
  bool isCollapsed(String treeNodeId) =>
      getTreenodeForDocumentNodeId(treeNodeId).treenode.isCollapsed;

  @override
  void setCollapsed(String treeNodeId, bool isCollapsed) {
    root.replaceTreenodeById(
        treeNodeId, (p) => p.copyWith(isCollapsed: isCollapsed));
  }

  @override
  bool isHidden(String documentNodeId) =>
      getNodeById(documentNodeId)!.getMetadataValue(isHiddenKey) == true;

  @override
  void setHidden(String documentNodeId, bool isHidden) {
    final node = getNodeById(documentNodeId)!;
    replaceNodeById(
        documentNodeId, node.copyWithAddedMetadata({isHiddenKey: isHidden}));
  }

  @override
  void moveNode({required String nodeId, required int targetIndex}) {
    final node = _root.getDocumentNodeById(nodeId);
    if (node == null) {
      outlineDocLog.warning('moveNode called on non-existing node $nodeId');
      return;
    }
    assert(node is! TitleNode,
        'moveNode called on a TitleNode, this is not supported; internal error');
    final nodePath = _root.getDocumentNodePathById(nodeId);
    final treenode = _root.getTreenodeByPath(nodePath!.treenodePath)!;
    root = root.replaceTreenodeById(
        treenode.id, (p) => p.copyRemoveContentNode(docNodeId: nodeId));
    insertNodeAt(targetIndex, node);
  }

  @override
  void replaceNode(
      {required DocumentNode oldNode, required DocumentNode newNode}) {
    final oldNodeResult = _root.getTreenodeContainingDocumentNode(oldNode.id);
    if (oldNodeResult == null || oldNodeResult.path.isEmpty) {
      outlineDocLog.warning('replaceNode called on non-existing node $oldNode');
      return;
    }
    // assert(oldNode is! TitleNode && newNode is! TitleNode,
    //     'replaceNode called on a TitleNode, this is not supported; program error');
    final treenode = oldNodeResult.treenode;
    if (oldNode is TitleNode) {
      assert(newNode is TitleNode,
          'Tried to replace a TitleNode with a non-TitleNode');
      root = _root.replaceTreenodeById(
          treenode.id, (p) => p.copyWith(titleNode: newNode as TitleNode));
    } else {
      assert(
          newNode is! TitleNode, 'Tried inserting a TitleNode in contentNodes');
      root = _root.replaceTreenodeById(treenode.id,
          (p) => p.copyReplaceContentNodeInTreenode(replaceNode: newNode));
    }
  }

  @override
  void onTransactionEnd(List<EditEvent> edits) {
    final documentChanges =
        edits.whereType<DocumentEdit>().map((edit) => edit.change).toList();
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
  void onTransactionStart() {}

  @override
  void reset() {
    // TODO: implement reset
    _root = _resetRoot.copyWithDeep();
    _didReset = true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineEditableDocument &&
          runtimeType == other.runtimeType &&
          _root == other.root;

  @override
  int get hashCode => _root.hashCode;

  @override
  void clear() {
    // TODO: implement clear
  }

  @override
  DocumentNode? getNodeAfterById(String nodeId) {
    final node = getNodeById(nodeId);
    return node == null ? null : getNodeAfter(node);
  }

  @override
  DocumentNode? getNodeBeforeById(String nodeId) {
    final node = getNodeById(nodeId);
    return node == null ? null : getNodeBefore(node);
  }

  @override
  void replaceNodeById(String nodeId, DocumentNode newNode) {
    final node = getNodeById(nodeId);
    if (node == null) {
      throw Exception('Could not find node with ID: $nodeId');
    }
    replaceNode(oldNode: node, newNode: newNode);
  }
}
