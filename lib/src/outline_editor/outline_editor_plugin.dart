import 'package:outline_editor/src/components/outline_paragraph_component.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineEditorPlugin extends SuperEditorPlugin {
  const OutlineEditorPlugin();

  @override
  void attach(Editor editor) {
    assert(editor.document is OutlineDocument, 'OutlineEditorPlugin '
      'expects a Document that implements StructureDocument');
    editor.reactionPipeline.insert(0, OutlineStructureReaction());
    (editor.document as OutlineDocument).rebuildStructure();
  }

  @override
  void detach(Editor editor) {
    editor.reactionPipeline
        .removeWhere((element) => element is OutlineStructureReaction);
  }

  @override
  List<ComponentBuilder> get componentBuilders => [
    const OutlineParagraphComponentBuilder(),
  ];
}
