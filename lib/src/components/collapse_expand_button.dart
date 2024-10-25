import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/commands/change_collapsed_state.dart';
import 'package:outline_editor/src/components/component_animations.dart';
import 'package:outline_editor/src/components/outline_component_base.dart';
import 'package:outline_editor/src/util/logging.dart';

class CollapseExpandButton extends StatelessWidget {
  const CollapseExpandButton({
    super.key,
    required this.editor,
    required this.viewModel,
  });

  final Editor editor;
  final OutlineComponentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        commandLog.fine('tap! setting isCollapsed to ${!viewModel.isCollapsed}');
        editor.execute([
          ChangeCollapsedStateRequest(
            treenodeId: (editor.document as OutlineTreeDocument).getOutlineTreenodeByDocumentNodeId(viewModel.nodeId).id,
            isCollapsed: !viewModel.isCollapsed,
          ),
        ]);
      }, // toggleFoldChildren,
      child: SizedBox(
        width: indentPerLevel, // widget.horizontalChildOffset,
        height: 28, //widget.foldControlHeight,
        child: viewModel.hasChildren
            ? AnimatedRotation(
                // key: ValueKey<String>(widget.treeNode.id),
                turns: viewModel.isCollapsed ? 0.0 : 0.25,
                duration: animationDuration,
                curve: animationCurve,
                child: const Icon(
                  Icons.arrow_right,
                  size: 28,
                  color: Color(0xFF999999),
                ),
              )
            : const Icon(
                Icons.horizontal_rule,
                size: 14,
                color: Color(0xFFB5B6B7),
              ),
      ),
    );
  }
}
