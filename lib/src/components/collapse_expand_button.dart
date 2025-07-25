import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class CollapseExpandButton extends StatelessWidget {
  const CollapseExpandButton({
    super.key,
    required this.editor,
    required this.docNodeId,
    this.width = 28,
    this.height = 28,
  });

  final Editor editor;
  final String docNodeId;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final document = editor.document as OutlineEditableDocument;
    final outlineTreenode =
        document.getTreenodeWithPathByDocumentNodeId(docNodeId).treenode;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        commandLog.fine(
            'tap! setting isCollapsed to ${!outlineTreenode.isCollapsed}');
        editor.execute([
          ChangeCollapsedStateRequest(
            treenodeId: outlineTreenode.id,
            isCollapsed: !outlineTreenode.isCollapsed,
          ),
        ]);
      }, // toggleFoldChildren,
      child: SizedBox(
        width: width, // widget.horizontalChildOffset,
        height: height, //widget.foldControlHeight,
        child: outlineTreenode.children.isNotEmpty
            ? AnimatedRotation(
                // key: ValueKey<String>(widget.treeNode.id),
                turns: outlineTreenode.isCollapsed ? 0.0 : 0.25,
                duration: animationDuration,
                curve: animationCurve,
                child: const Icon(
                  Icons.arrow_right,
                  size: 28,
                  color: Color(0xFF999999),
                ),
              )
            : AnimatedSwitcher(
                duration: animationDuration,
                child: outlineTreenode.isCollapsed
                    ? Icon(
                        Icons.more_horiz,
                        size: 14,
                        color: Color(0xFFB5B6B7),
                      )
                    : Icon(
                        Icons.horizontal_rule,
                        size: 14,
                        color: Color(0xFFB5B6B7),
                      ),
              ),
      ),
    );
  }
}
