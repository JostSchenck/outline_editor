import 'package:outline_editor/src/outline_document/outline_treenode.dart';
import 'package:super_editor/super_editor.dart';

const isHiddenKey = 'isHidden';

/// Interface class that has to be implemented by the Document
/// class to be used in an outline editor.
abstract mixin class OutlineDocument implements Document {
  List<OutlineTreenode> get rootNodes;

  OutlineTreenode getTreeNodeForDocumentNode(String nodeId);

  int getIndentationLevel(String nodeId);

  /// At which position in the parent's children or the root nodes
  /// a certain [DocumentNode] is located, ie. 0 for the first child, 1 for the
  /// second, etc. Returns -1 if it does not find nodeId.
  int indexInChildren(String nodeId) {
    for(var rootNode in rootNodes) {
      int index = rootNode.getIndexInChildren(nodeId);
      if (index!=-1) {
        return index;
      }
    }
    return -1;
  }

  bool isCollapsed(String nodeId);
  void setCollapsed(String nodeId, bool isCollapsed);

  bool isHidden(String nodeId);
  void setHidden(String nodeId, bool isHidden);

  /// Return visibility of the [DocumentNode] with the given id, taking
  /// folding state of tree nodes as well as document nodes into account.
  bool isVisible(String documentNodeId);

  /// Returns the last visible node in the document before `pos`, or the node
  /// at `pos` itself, if it is visible. Note that
  /// this may not correspond to a selectable component later on. The first
  /// node in a document is always visible, so this method will always return
  /// a node.
  DocumentNode getLastVisibleNode(DocumentPosition pos);
  /// Returns the first visible node in the document after `pos`, or the node
  /// at `pos` itself, if it is visible. Note that
  /// this may not correspond to a selectable component later on. Returns
  /// null, if there is no visible node later in the document.
  DocumentNode? getNextVisibleNode(DocumentPosition pos);

  void rebuildStructure();
}
