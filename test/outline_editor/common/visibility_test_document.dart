import 'package:outline_editor/outline_editor.dart';

OutlineEditableDocument getVisibilityTestDocument() {
  OutlineEditableDocument document =
      OutlineEditableDocument(treenodeBuilder: defaultOutlineTreenodeBuilder);
  document.root = TreeEditor.insertChild(
    parent: document.root,
    child: OutlineTreenode(
      id: 'tn_1',
      titleNode: TitleNode(id: '1title', text: AttributedText('Title node')),
      contentNodes: [
        ParagraphNode(
          id: '1',
          text: AttributedText('One more'),
        ),
      ],
      children: [
        OutlineTreenode(
          id: 'tn_2',
          titleNode:
              TitleNode(id: '2title', text: AttributedText('Title node')),
          contentNodes: [
            ParagraphNode(
              id: '2',
              text: AttributedText('Two more'),
            ),
          ],
          isCollapsed: true,
          children: [
            OutlineTreenode(
              id: 'tn_3',
              titleNode:
                  TitleNode(id: '3title', text: AttributedText('Title node')),
              contentNodes: [
                ParagraphNode(
                  id: '3',
                  text: AttributedText('Three more'),
                ),
              ],
              children: [
                OutlineTreenode(
                  id: 'tn_4',
                  titleNode: TitleNode(
                      id: '4title', text: AttributedText('Title node')),
                  contentNodes: [
                    ParagraphNode(
                      id: '4',
                      text: AttributedText('Four more'),
                    ),
                  ],
                  children: [],
                ),
              ],
            ),
          ],
        ),
        OutlineTreenode(
          id: 'tn_5',
          titleNode:
              TitleNode(id: '5title', text: AttributedText('Title node')),
          contentNodes: [
            ParagraphNode(
              id: '5',
              text: AttributedText('Another ...'),
            ),
          ],
          isCollapsed: true,
          children: [
            OutlineTreenode(
              id: 'tn_6',
              titleNode:
                  TitleNode(id: '6title', text: AttributedText('Title node')),
              contentNodes: [
                ParagraphNode(
                  id: '6',
                  text: AttributedText('and another'),
                ),
              ],
              children: [],
            ),
          ],
        ),
      ],
    ),
  );
  return document;
}
