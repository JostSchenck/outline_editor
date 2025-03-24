import 'package:outline_editor/outline_editor.dart';

class TreenodeDocumentChange extends DocumentChange {
  TreenodeDocumentChange(this.treenodeId);

  final String treenodeId;
}

class TreenodeInsertedDocumentChange extends TreenodeDocumentChange {
  TreenodeInsertedDocumentChange(super.treenodeId, this.path);

  final TreenodePath path;
}

class TreenodeDeletedDocumentChange extends TreenodeDocumentChange {
  TreenodeDeletedDocumentChange(super.treenodeId, this.path);

  final TreenodePath path;
}

class TreenodeMovedDocumentChange extends TreenodeDocumentChange {
  TreenodeMovedDocumentChange(super.treenodeId, this.oldPath, this.newPath);

  final TreenodePath oldPath;
  final TreenodePath newPath;
}
