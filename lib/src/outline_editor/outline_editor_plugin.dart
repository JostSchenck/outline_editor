import 'package:outline_editor/src/commands/change_collapsed_state.dart';
import 'package:outline_editor/src/commands/insert_outline_treenode.dart';
import 'package:outline_editor/src/outline_editor/keyboard_actions.dart';
import 'package:outline_editor/src/reactions/node_visibility_reaction.dart';
import 'package:outline_editor/src/components/outline_paragraph_component.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineEditorPlugin extends SuperEditorPlugin {
  const OutlineEditorPlugin({
    required this.editor,
  });

  final Editor editor;

  @override
  void attach(Editor editor) {
    assert(
        editor.document is OutlineDocument,
        'OutlineEditorPlugin '
        'expects a Document that implements OutlineDocument');
    editor.reactionPipeline.insert(0, OutlineStructureReaction());
    editor.reactionPipeline.insert(0, NodeVisibilityReaction(editor: editor));
    editor.requestHandlers.addAll(
      [
        (request) => request is ChangeCollapsedStateRequest
            ? ChangeCollapsedStateCommand(
                nodeId: request.nodeId,
                isCollapsed: request.isCollapsed,
              )
            : null,
        (request) => request is InsertOutlineTreenodeRequest
        ? InsertOutlineTreenodeCommand(
          existingNode: request.existingNode,
          newNode: request.newNode,
          createChild: request.createChild,
          index: request.index,
        )
            : null,
      ],
    );
    (editor.document as OutlineDocument).rebuildStructure();
  }

  @override
  void detach(Editor editor) {
    editor.reactionPipeline
        .removeWhere((element) => element is OutlineStructureReaction);
  }

  @override
  List<ComponentBuilder> get componentBuilders => [
        OutlineTitleComponentBuilder(editor: editor),
        OutlineParagraphComponentBuilder(editor: editor),
      ];

  @override
  List<DocumentKeyboardAction> get keyboardActions => [
    insertTreenodeOnShiftOrCtrlEnter,
  ];
}
