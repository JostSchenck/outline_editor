import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

class DocumentStructureReaction extends EditReaction {
  DocumentStructureReaction();

  @override
  void modifyContent(EditContext editorContext,
      RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    // TODO: implement modifyContent
    final DocumentStructure structure = editorContext.find('structure');
    // TODO: only rebuild structure when it may have changed, depending on changeList
    for (var event in changeList) {
      if (event is DocumentEdit) {
        structure.rebuildStructure();
        break;
      }
    }
    super.modifyContent(editorContext, requestDispatcher, changeList);
  }
}

class DocumentStructureChangeEvent extends DocumentEdit {
  DocumentStructureChangeEvent(super.change);

  @override
  String toString() => 'DocumentStructureChangeEvent -> $change';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentStructureChangeEvent &&
          runtimeType == other.runtimeType &&
          change == other.change;
}
