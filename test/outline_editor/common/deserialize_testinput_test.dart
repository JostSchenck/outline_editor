import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';

import 'build_test_document.dart';

const testInputTestString = '''
root:root
  1:Dies ist ein TitleNode
    > p1:Content-Paragraph
    > p2:Noch ein Content-Paragraph
    2:Dies ist noch ein TitleNode
      > p3:mit einem ContentParagraph
      3:Dies ist ein Enkelkind
        > p4:and it's not about whitespace before
    4:weiteres Kind ohne Content
    5:und Kind Nr. 3
      > p5:mit Content mit Abstand am Ende 
  6:Weiterer RootNode ohne Content
''';

const titleNodeCharacter = '#';
const textDelimiter = ':';

main() {
  late OutlineEditableDocument<BasicOutlineTreenode> document;

  setUp(() {
    document = buildTestDocumentFromString(testInputTestString);
    print(document.toPrettyTestString());
  });

  group(
      'simple String format for the generation of OutlineTreeDocuments for testing work',
      () {
    test('correct node hierarchy is generated', () {
      expect(document.root.children.length, 2,
          reason: document.root.children[1].toString());
      expect(document.root.children[0].children.length, 3);
      expect(document.root.children[0].children[0].children.length, 1);
      expect(
          document.root.children[0].children[0].children[0].children.length, 0);
      expect(document.root.children[1].children.length, 0);
    });
    test('Treenode IDs are correctly used as specified', () {
      expect(document.getTreenodeByPath([0, 0, 0]).id, '3');
      expect(document.getTreenodeByPath([0, 2]).id, '5');
    });
    test('Content node IDs are correctly derived from treenode ID', () {
      expect(document.getTreenodeByPath([0]).titleNode.id, '1');
      expect(document.getTreenodeByPath([0]).contentNodes[0].id, 'p1');
      expect(document.getTreenodeByPath([0]).contentNodes[1].id, 'p2');
      expect(document.getTreenodeByPath([0, 0, 0]).titleNode.id, '3');
      expect(document.getTreenodeByPath([0, 0, 0]).contentNodes[0].id, 'p4');
    });
    test('Node text is correctly set', () {
      expect(document.getTreenodeByPath([0, 0]).titleNode.text.toPlainText(),
          'Dies ist noch ein TitleNode');
      expect(document.getTreenodeByPath([0, 0, 0]).titleNode.text.toPlainText(),
          'Dies ist ein Enkelkind');
      expect(
          (document.getTreenodeByPath([0, 2]).contentNodes[0] as TextNode)
              .text
              .toPlainText(),
          'mit Content mit Abstand am Ende ');
    });
  });
}
