import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

class DocumentStructureReaction extends EditReaction {
  DocumentStructureReaction();

  @override
  void modifyContent(EditContext editorContext, RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    // TODO: implement modifyContent
    final DocumentStructure structure = editorContext.find('structure');
    // TODO: only rebuild structure when it may have changed, depending on changeList
    structure.rebuildStructure();
    super.modifyContent(editorContext, requestDispatcher, changeList);
  }
}