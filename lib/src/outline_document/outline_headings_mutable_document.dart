import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/outline_document/outline_treenode.dart';
import 'package:outline_editor/src/util/logging.dart';

class OutlineHeadingsMutableDocument extends OutlineMutableDocument {
  OutlineHeadingsMutableDocument({
    super.nodes,
  });

  @override
  void rebuildStructure() {
    outlineDocLog.fine('rebuilding OutlineDocument structure from header attributions');
    // root = OutlineTreenode(id: 'root', document: this);
    root.children.clear();
    List<OutlineTreenode> treeNodeStack = [root];
    // we start at 1 because our already existing root node is depth 0 and every
    // node found will be put into a child.
    int currentDepth = 1;
    for (final documentNode in this) {
      final currentAttribution = documentNode.metadata['blockType'];
      var createNewTreenode = false;

      if (currentAttribution == null || currentAttribution==paragraphAttribution) {
        outlineDocLog.fine('no header for node ${documentNode.id}, assuming depth $currentDepth');
        if (root.children.isEmpty) {
          createNewTreenode = true;
        }
      } else if (currentAttribution == header1Attribution) {
        currentDepth = 1;
        createNewTreenode = true;
      } else if (currentAttribution == header2Attribution) {
        currentDepth = 2;
        createNewTreenode = true;
      } else if (currentAttribution == header3Attribution) {
        currentDepth = 3;
        createNewTreenode = true;
      } else if (currentAttribution == header4Attribution) {
        currentDepth = 4;
        createNewTreenode = true;
      } else if (currentAttribution == header5Attribution) {
        currentDepth = 5;
        createNewTreenode = true;
      } else if (currentAttribution == header6Attribution) {
        currentDepth = 6;
        createNewTreenode = true;
      } else {
        outlineDocLog.fine(
            'unknown attribution $currentAttribution for node ${documentNode
                .id}, assuming depth $currentDepth');
      }

      if (createNewTreenode) {
        final newTreeNode = OutlineTreenode(
            document: this,
            documentNodeIds: [documentNode.id],
            id: 'tn_${documentNode.id}',
        );
        if (currentDepth == treeNodeStack.length) {
          // we found a new child to the top one on stack; add it to the
          // children and push it on the stack
          treeNodeStack.last.addChild(newTreeNode);
          treeNodeStack.add(newTreeNode);
        } else if (currentDepth > 0 && currentDepth <= treeNodeStack.length - 1) {
          // we found a new sibling to one on stack; add it to the children of
          // the parent of the last one on this depth of stack, then shorten the
          // stack to this one and push our new treeNode
          treeNodeStack[currentDepth - 1].addChild(newTreeNode);
          treeNodeStack.removeRange(currentDepth, treeNodeStack.length);
          treeNodeStack.add(newTreeNode);
        } else {
          if (currentDepth > treeNodeStack.length) {
            throw Exception('depth may only move up in single steps '
                'but a node of depth $currentDepth was found following one of '
                'depth ${treeNodeStack.length - 1}');
          }
          if (currentDepth < 0) {
            throw Exception('illegal depth of $currentDepth found');
          }
        }
      }
      else {
        treeNodeStack.last.documentNodeIds.add(documentNode.id);
      }
    }
  }
}