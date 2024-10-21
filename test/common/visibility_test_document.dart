import 'package:outline_editor/outline_editor.dart';

OutlineTreeDocument getVisibilityTestDocument() {
  OutlineTreeDocument document = OutlineTreeDocument();
  document.root.addChild(
    OutlineTreenode(
      id: 'tn_1',
      document: document,
      documentNodes: [
        ParagraphNode(
          id: '1',
          text: AttributedText('One more'),
        ),
      ],
      children: [
        OutlineTreenode(
          id: 'tn_2',
          document: document,
          documentNodes: [
            ParagraphNode(
              id: '2',
              text: AttributedText('Two more'),
            ),
          ],
          collapsed: true,
          children: [
            OutlineTreenode(
              id: 'tn_3',
              document: document,
              documentNodes: [
                ParagraphNode(
                  id: '3',
                  text: AttributedText('Three more'),
                ),
              ],
              children: [
                OutlineTreenode(
                  id: 'tn_4',
                  document: document,
                  documentNodes: [
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
          document: document,
          documentNodes: [
            ParagraphNode(
              id: '5',
              text: AttributedText('Another ...'),
            ),
          ],
          collapsed: true,
          children: [
            OutlineTreenode(
              id: 'tn_6',
              document: document,
              documentNodes: [
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
  document.rebuildStructure();
  return document;
}
