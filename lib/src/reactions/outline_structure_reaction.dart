import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/util/logging.dart';

class OutlineStructureReaction extends EditReaction {
  OutlineStructureReaction();

  @override
  void modifyContent(EditContext editorContext,
      RequestDispatcher requestDispatcher, List<EditEvent> changeList) {
    assert(editorContext.document is OutlineDocument);
    final outlineDoc = editorContext.document as OutlineDocument;
    for (var editevent in changeList) {
      if (editevent is DocumentEdit) {
        outlineDoc.rebuildStructure();
      }
      super.modifyContent(editorContext, requestDispatcher, changeList);
    }
  }
}

class OutlineStructureChangeEvent extends DocumentEdit {
  OutlineStructureChangeEvent(super.change);

  @override
  String toString() => 'OutlineStructureChangeEvent -> $change';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutlineStructureChangeEvent &&
          runtimeType == other.runtimeType &&
          change == other.change;

}

/// Base class for all [DocumentChange]s that affect the document's structure
/// in contrast to a single document node.
class OutlineStructureChange extends DocumentChange {
  const OutlineStructureChange(this.treeNodeId);

  final String treeNodeId;
}
