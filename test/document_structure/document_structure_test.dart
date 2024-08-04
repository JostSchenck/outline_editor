// import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:structured_rich_text_editor/src/document_structure/document_structure.dart';
import 'package:super_editor/super_editor.dart';
// import 'package:flutter_test_runners/flutter_test_runners.dart';

void main() {
  group("DocumentStructure", ()
  {
    test('Correct structure is generated out of depth values in metadata', () {
      final doc = MutableDocument(
        nodes: [
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('Root-Node'),
            metadata: {
              'depth': 0,
            },
          ),
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('Dies hier ist ein erstes Child.'),
            metadata: {
              'depth': 1,
            },
          ),
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('Dies hier ist ein erstes Enkelkind.'),
            metadata: {
              'depth': 2,
            },
          ),
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('Dies hier ist ein zweites Enkelkind.'),
            metadata: {
              'depth': 2,
            },

          ),
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('Dies hier ist ein Ur-Enkel.'),
            metadata: {
              'depth': 3,
            },

          ),
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText('Dies hier ist ein zweites Child.'),
            metadata: {
              'depth': 1,
            },
          ),
        ],
      );

      final strobj = MetadataDepthDocumentStructure(doc);

      expect(strobj.structure.length, 1);
      expect(strobj.structure.first.children.length, 2);
      expect(strobj.structure.first.children.first.children.length, 2);
      expect(strobj.structure.first.children.first.children.last.children.length, 1);
      expect(strobj.structure.first.children.last.children.length, 0);
      expect((doc.getNodeById(
          strobj.structure.first.documentNodeIds.first) as ParagraphNode).text
          .text, 'Root-Node');
      expect((doc.getNodeById(
          strobj.structure.first.children.first.children.last.children.first.documentNodeIds.first) as ParagraphNode).text
          .text, 'Dies hier ist ein Ur-Enkel.');
    });
  });
}
