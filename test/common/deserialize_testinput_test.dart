import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';

const testInputTestString = '''
# 1:Dies ist ein TitleNode
>Content-Paragraph
>Noch ein Content-Paragraph
  ## 2:Dies ist noch ein TitleNode
  >mit einem ContentParagraph
    ### 3:Dies ist ein Enkelkind
>and it's not about whitespace before the '>' character
## 4:weiteres Kind ohne Content
## 5:und Kind Nr. 3
>mit Content mit Abstand am Ende 
# 6:Weiterer RootNode ohne Content
''';

const titleNodeCharacter = '#';
const textDelimiter = ':';

bool isTitleNode(String line) => line.startsWith(titleNodeCharacter);

({int depth, String id, String text}) getTitleNodeData(String trimmedline) {
  int count = 0;
  for (int i = 0; i < trimmedline.length; i++) {
    if (trimmedline[i] == titleNodeCharacter) {
      count++;
    } else {
      break;
    }
  }
  // strip the title node characters and following white space until ID
  final lineRest = trimmedline.substring(count).trimLeft();
  // get ID and text
  final delimiterIndex = lineRest.indexOf(textDelimiter);
  final id = lineRest.substring(0, delimiterIndex);
  final text = lineRest.substring(delimiterIndex + 1);
  return (depth: count, id: id, text: text);
}

OutlineTreeDocument deserializeTestInput(String str) {
  final doc = OutlineTreeDocument(root: OutlineTreenode(id: uuid.v4()));
  final lines = const LineSplitter().convert(str);
  int contentNodeCounter = 0;
  final List<OutlineTreenode> treenodeStack = [doc.root];
  for (var line in lines) {
    final trline = line.trimLeft();
    if (trline.startsWith('#')) {
      // curTreenode
      contentNodeCounter = 0;
      final titleNodeData = getTitleNodeData(trline);
      final curTreenode = OutlineTreenode(
        id: titleNodeData.id,
        titleNode: TitleNode(
            id: '${titleNodeData.id}title',
            text: AttributedText(titleNodeData.text)),
      );
      if (titleNodeData.depth > treenodeStack.length) {
        throw Exception(
            'error in test code: illegal outline hierarchy in string input');
      }
      treenodeStack.removeRange(titleNodeData.depth, treenodeStack.length);
      treenodeStack.last.addChild(curTreenode);
      treenodeStack.add(curTreenode);
    } else {
      if (treenodeStack.length < 2) {
        throw Exception(
            'content must start with title node, error in testcode');
      }
      if (trline.startsWith('>')) {
        // this is a new ParagraphNode
        final paragraphNode = ParagraphNode(
          id: '${treenodeStack.last.id}-$contentNodeCounter',
          text: AttributedText(trline.substring(1)),
        );
        treenodeStack.last.contentNodes.add(paragraphNode);
        contentNodeCounter++;
      } else {
        // this is a continuation to the last ParagraphNode
        var textNode = (treenodeStack.last.contentNodes.last as TextNode);
        textNode = textNode.copyTextNodeWith(
            text: AttributedText('${textNode.text.toPlainText()}$trline'));
      }
    }
  }
  return doc;
}

main() {
  late OutlineTreeDocument document;

  setUp(() {
    document = deserializeTestInput(testInputTestString);
  });

  group(
      'simple String format for the generation of OutlineTreeDocuments for testing work',
      () {
    test('title nodes are correctly counted', () {
      expect(getTitleNodeData('### 1:Asdf'), (depth: 3, id: '1', text: 'Asdf'));
      expect(getTitleNodeData('#25ad:Schubidu '),
          (depth: 1, id: '25ad', text: 'Schubidu '));
    });

    test('correct node hierarchy is generated', () {
      expect(document.root.children.length, 2);
      expect(document.root.children[0].children.length, 3);
      expect(document.root.children[0].children[0].children.length, 1);
      expect(
          document.root.children[0].children[0].children[0].children.length, 0);
      expect(document.root.children[1].children.length, 0);
    });
    test('Treenode IDs are correctly used as specified', () {
      expect(document.getOutlineTreenodeByPath([0, 0, 0]).id, '3');
      expect(document.getOutlineTreenodeByPath([0, 2]).id, '5');
    });
    test('Content node IDs are correctly derived from treenode ID', () {
      expect(document.getOutlineTreenodeByPath([0]).titleNode.id, '1title');
      expect(document.getOutlineTreenodeByPath([0]).contentNodes[0].id, '1-0');
      expect(document.getOutlineTreenodeByPath([0]).contentNodes[1].id, '1-1');
      expect(
          document.getOutlineTreenodeByPath([0, 0, 0]).titleNode.id, '3title');
      expect(document.getOutlineTreenodeByPath([0, 0, 0]).contentNodes[0].id,
          '3-0');
    });
    test('Node text is correctly set', () {
      expect(
          document
              .getOutlineTreenodeByPath([0, 0])
              .titleNode
              .text
              .toPlainText(),
          'Dies ist noch ein TitleNode');
      expect(
          document
              .getOutlineTreenodeByPath([0, 0, 0])
              .titleNode
              .text
              .toPlainText(),
          'Dies ist ein Enkelkind');
      expect(
          (document.getOutlineTreenodeByPath([0, 2]).contentNodes[0]
                  as TextNode)
              .text
              .toPlainText(),
          'mit Content mit Abstand am Ende ');
    });
  });
}
