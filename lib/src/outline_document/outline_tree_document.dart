import 'dart:math';

import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';
import 'package:outline_editor/src/util/logging.dart';

typedef TreenodeBuilder = OutlineTreenode Function({
  String? id,
  TitleNode? titleNode,
  List<DocumentNode>? contentNodes,
});

OutlineTreenode defaultOutlineTreenodeBuilder({
  String? id,
  TitleNode? titleNode,
  List<DocumentNode>? contentNodes,
}) =>
    OutlineTreenode(
      id: id ?? uuid.v4(),
      contentNodes: contentNodes ?? [],
      titleNode: titleNode ??
          TitleNode(
            id: uuid.v4(),
            text: AttributedText(''),
          ),
    );

class OutlineTreeDocument<T extends OutlineTreenode>
    with OutlineDocument<T>, Iterable<DocumentNode>
    implements MutableDocument {
  OutlineTreeDocument({
    this.treenodeBuilder = defaultOutlineTreenodeBuilder,
    T? logicalRoot,
    List<T>? rootTreeNodes,
  }) : _root = logicalRoot ?? treenodeBuilder(id: 'root') as T {
    if (rootTreeNodes != null) {
      for (var tn in rootTreeNodes) {
        _root.addChild(tn);
      }
    }
    _resetRoot = _root.deepCopy() as T;
  }

  /// Constructs an OutlineTreeDocument<T> with only an empty treenode with
  /// an empty title node and one empty paragraph.
  factory OutlineTreeDocument.empty({
    String? treenodeId,
    String? titleNodeId,
    String? paragraphNodeId,
    TreenodeBuilder? treenodeBuilder,
  }) {
    final doc = OutlineTreeDocument<T>(
      treenodeBuilder: treenodeBuilder ?? defaultOutlineTreenodeBuilder,
    );
    doc.root.addChild(doc.treenodeBuilder(
        id: treenodeId ?? uuid.v4(),
        titleNode:
            TitleNode(id: titleNodeId ?? uuid.v4(), text: AttributedText('')),
        contentNodes: [
          ParagraphNode(
              id: paragraphNodeId ?? uuid.v4(), text: AttributedText('')),
        ]));
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
    _didReset = true;
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

  /// The iterator for an OutlineTreeDocument does not iterate over the
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
    _root.lastOutlineTreeNodeInSubtree.contentNodes.add(node);
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
    final node = nodeList[index];
    _root
        .getOutlineTreenodeByDocumentNodeId(node.id)
        ?.contentNodes
        .remove(node);
  }

  @override
  bool deleteNode(String nodeId) {
    final outlineNode = _root.getOutlineTreenodeByDocumentNodeId(nodeId);
    if (outlineNode == null) {
      outlineDocLog
          .warning('deleteNode: node $nodeId not found in outline tree');
      return false;
    }
    final docNode = outlineNode.getDocumentNodeById(nodeId);
    return outlineNode.contentNodes.remove(docNode);
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
    if (other is OutlineTreeDocument<T>) {
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
  /// Only in the special case of `index==0` it will prepend to the root node
  /// to a new treenode.
  // TODO: TEST!!!
  @override
  void insertNodeAt(
    int index,
    DocumentNode node,
  ) {
    if (index == 0) {
      // The node is to be inserted at the start of the document before the
      // first node. This is illegal in an OutlineTreeDocument, because we can't
      // insert something in the same OutlineTreenode before the TitleNode.
      throw Exception('insertNodeAt tried to insert a DocumentNode before '
          'the first OutlineTreenode');
      // _root.children.insert(0,
      //     OutlineTreenode(id: uuid.v4(), document: this, contentNodes: [node]));
    }
    if (index == length) {
      // Node is appended at the end of the document. Easy:
      final lastTreenode = _root.getLastOutlineTreenodeInSubtree();
      if (node is TitleNode) {
        throw Exception('A TitleNode must not be inserted using insertNodeXXX'
            ' methods; instead, a Treenode must be inserted explicitly');
        // // a TitleNode always starts a new OutlineTreenode
        // Implicitly creating a Treenode would corrupt our undo history, as
        // the generated uuid makes this call indeterministic.
        // (lastTreenode.parent!.addChild(treenodeBuilder(
        //   id: uuid.v4(),
        //   contentNodes: [node],
        // )));
      } else {
        lastTreenode.contentNodes.add(node);
      }
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
    final path = _root.getPathToDocumentNode(existingNode);
    final treenode = getOutlineTreenodeByPath(path!.treenodePath);
    if (existingNode is TitleNode) {
      // A TitleNode is always the first DocumentNode in an OutlineTreenode.
      // This means we can not add to treenode, but must prepend to it.
      if (node is TitleNode) {
        throw Exception('A TitleNode must not be inserted using insertNodeXXX'
            ' methods; instead, a Treenode must be inserted explicitly');
        // // Every TitleNode must correspond to an OutlineTreenode, so we have
        // // to insert one now. While new OutlineTreenodes should be inserted as
        // // such programmatically, we try to do something sensible and just
        // // add a sibling.
        // // Implicitly creating a Treenode would corrupt our undo history, as
        // // the generated uuid makes this call indeterministic.
        // treenode.parent?.addChild(
        //     treenodeBuilder(
        //       id: uuid.v4(),
        //       contentNodes: [node],
        //     ),
        //     treenode.childIndex);
      } else {
        treenode.outlineTreenodeBefore.contentNodes.add(node);
      }
      return;
    }
    // okay, index pointed to a simple content node. Now, if inserted node is
    // a TitleNode, this effectively means splitting our OutlineTreenode, else
    // it means just inserting.
    if (node is TitleNode) {
      throw Exception('A TitleNode must not be inserted using insertNodeXXX'
          ' methods; instead, a Treenode must be inserted explicitly');
      // // Implicitly creating a Treenode would corrupt our undo history, as
      // // the generated uuid makes this call indeterministic.
      // final newNode = treenodeBuilder(
      //   id: uuid.v4(),
      //   contentNodes: treenode.contentNodes.sublist(
      //     // minus 1, as a 0 path always points to the title node
      //     path.docNodeIndex - 1,
      //   ),
      // );
      // treenode.parent!.addChild(newNode, treenode.childIndex + 1);
      // // minus 1, as a 0 path always points to the title node
      // treenode.contentNodes
      //     .removeRange(path.docNodeIndex - 1, treenode.contentNodes.length);
    } else {
      // minus 1, as a 0 path always points to the title node
      treenode.contentNodes.insert(path.docNodeIndex - 1, node);
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
      {required String existingNodeId, required DocumentNode newNode}) {
    // this is the least efficient way, do this better when problems arise
    insertNodeAt(getNodeIndexById(existingNodeId), newNode);
  }

  /// Inserts a node right after a given existing node. While this is trivial
  /// in a simple [Document], the outline structure of [OutlineTreeDocument]
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
    // this is the least efficient way, do this better when problems arise
    insertNodeAt(getNodeIndexById(existingNodeId) + 1, newNode);
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
        'moveNode called on a TitleNode, this is not supported; program error');
    final nodePath = _root.getPathToDocumentNode(node);
    final outlineNode = _root.getOutlineTreenodeByPath(nodePath!.treenodePath)!;
    outlineNode.contentNodes.remove(node);
    insertNodeAt(targetIndex, node);
  }

  @override
  void replaceNode(
      {required DocumentNode oldNode, required DocumentNode newNode}) {
    final oldNodePath = _root.getPathToDocumentNode(oldNode);
    if (oldNodePath == null || oldNodePath.treenodePath.isEmpty) {
      outlineDocLog.warning('replaceNode called on non-existing node $oldNode');
      return;
    }
    // assert(oldNode is! TitleNode && newNode is! TitleNode,
    //     'replaceNode called on a TitleNode, this is not supported; program error');
    final treenode = _root.getOutlineTreenodeByPath(oldNodePath.treenodePath)!;
    if (oldNode is TitleNode) {
      assert(newNode is TitleNode,
          'Tried to replace a TitleNode with a non-TitleNode');
      treenode.titleNode = newNode as TitleNode;
    } else {
      assert(
          newNode is! TitleNode, 'Tried inserting a TitleNode in contentNodes');
      treenode.contentNodes.remove(oldNode);
      treenode.contentNodes.insert(oldNodePath.docNodeIndex - 1, newNode);
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
    _root = _resetRoot.deepCopy() as T;
    _didReset = true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineTreeDocument &&
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
