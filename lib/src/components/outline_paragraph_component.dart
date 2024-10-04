import 'package:flutter/material.dart';
import 'package:structured_rich_text_editor/src/components/common_animation_tools.dart';
import 'package:structured_rich_text_editor/structured_rich_text_editor.dart';

class OutlineParagraphComponentViewModel
    extends SingleColumnLayoutComponentViewModel with TextComponentViewModel {
  OutlineParagraphComponentViewModel({
    required super.nodeId,
    required this.paragraphComponentViewModel,
    required this.indentLevel,
    this.isVisible = true,
    this.hasChildren = false,
    super.padding = EdgeInsets.zero,
  });

  final ParagraphComponentViewModel paragraphComponentViewModel;
  final int indentLevel;
  final bool isVisible;
  final bool hasChildren;

  @override
  bool get highlightWhenEmpty => paragraphComponentViewModel.highlightWhenEmpty;

  @override
  TextSelection? get selection => paragraphComponentViewModel.selection;

  @override
  Color get selectionColor => paragraphComponentViewModel.selectionColor;

  @override
  AttributedText get text => paragraphComponentViewModel.text;

  @override
  TextAlign get textAlignment => paragraphComponentViewModel.textAlignment;

  @override
  TextDirection get textDirection => paragraphComponentViewModel.textDirection;

  @override
  AttributionStyleBuilder get textStyleBuilder =>
      paragraphComponentViewModel.textStyleBuilder;

  @override
  OutlineParagraphComponentViewModel copy() {
    return OutlineParagraphComponentViewModel(
      nodeId: nodeId,
      paragraphComponentViewModel: paragraphComponentViewModel.copy(),
      indentLevel: indentLevel,
      isVisible: isVisible,
      hasChildren: hasChildren,
      padding: padding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is OutlineParagraphComponentViewModel &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          paragraphComponentViewModel == other.paragraphComponentViewModel &&
          indentLevel == other.indentLevel &&
          isVisible == other.isVisible &&
          hasChildren == other.hasChildren &&
          padding == other.padding;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      paragraphComponentViewModel.hashCode ^
      indentLevel.hashCode ^
      isVisible.hashCode ^
      hasChildren.hashCode ^
      padding.hashCode;

  @override
  set highlightWhenEmpty(bool highlight) =>
      paragraphComponentViewModel.highlightWhenEmpty = highlight;

  @override
  set selection(TextSelection? selection) =>
      paragraphComponentViewModel.selection = selection;

  @override
  set selectionColor(Color color) =>
      paragraphComponentViewModel.selectionColor = color;

  @override
  set text(AttributedText text) => paragraphComponentViewModel.text = text;

  @override
  set textAlignment(TextAlign alignment) =>
      paragraphComponentViewModel.textAlignment = alignment;

  @override
  set textDirection(TextDirection direction) =>
      paragraphComponentViewModel.textDirection = direction;

  @override
  set textStyleBuilder(AttributionStyleBuilder styleBuilder) =>
      paragraphComponentViewModel.textStyleBuilder = styleBuilder;
}

class OutlineParagraphComponentBuilder implements ComponentBuilder {
  const OutlineParagraphComponentBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    assert(
        document is StructuredDocument,
        'createViewModel needs a '
        'StructuredDocument, but ${document.runtimeType} was given');

    final paragraphViewModel = const ParagraphComponentBuilder()
        .createViewModel(document, node) as ParagraphComponentViewModel;
    return OutlineParagraphComponentViewModel(
      nodeId: node.id,
      paragraphComponentViewModel: paragraphViewModel,
      indentLevel:
          (document as StructuredDocument).getIndentationLevel(node.id),
      hasChildren: (document as StructuredDocument)
          .getTreeNodeForDocumentNode(node.id)
          .children
          .isNotEmpty,
    );
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    // first of all, we find the component that we want to defer to
    assert(componentViewModel is OutlineParagraphComponentViewModel,
        "componentViewModel is no OutlineParagraphComponentViewModel but a ${componentViewModel.runtimeType}");
    return OutlineParagraphComponent(
      key: componentContext.componentKey,
      outlineViewModel:
          componentViewModel as OutlineParagraphComponentViewModel,
    );
  }
}

class OutlineParagraphComponent extends StatefulWidget {
  const OutlineParagraphComponent({
    super.key,
    required this.outlineViewModel,
  });

  final OutlineParagraphComponentViewModel outlineViewModel;

  @override
  State createState() => _OutlineParagraphComponentState();
}

class _OutlineParagraphComponentState extends State<OutlineParagraphComponent>
    with
        ProxyDocumentComponent<OutlineParagraphComponent>,
        ProxyTextComposable {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable =>
      childDocumentComponentKey.currentState as TextComposable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // mainAxisSize: MainAxisSize.min,
      children: [
        // Indent on start side
        SizedBox(width: 20 * widget.outlineViewModel.indentLevel.toDouble()),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {}, // toggleFoldChildren,
          child: SizedBox(
            width: 30, // widget.horizontalChildOffset,
            height: 20, //widget.foldControlHeight,
            child: widget.outlineViewModel.hasChildren
                ? AnimatedRotation(
              // key: ValueKey<String>(widget.treeNode.id),
              turns: 0.0, // _isFolded ? 0.0 : 0.25,
              duration: animationDuration,
              curve: animationCurve,
              child: const Icon(
                Icons.arrow_right,
                size: 28,
                color: Color(0xFF999999),
              ),
            )
                : const Icon(
              Icons.horizontal_rule,
              size: 14,
              color: Color(0xFFB5B6B7),
            ),
          ),
        ),
        // widget.componentBuilder.createComponent(),
        Expanded(
          child: /*widget.componentBuilder
              .createComponent(componentContext, widget.wrappedViewModel),*/
              TextComponent(
            key: _textKey,
            text: widget.outlineViewModel.paragraphComponentViewModel.text,

            textStyleBuilder: widget
                .outlineViewModel.paragraphComponentViewModel.textStyleBuilder,
            textScaler:
                widget.outlineViewModel.paragraphComponentViewModel.textScaler,
            textAlign: widget
                .outlineViewModel.paragraphComponentViewModel.textAlignment,
            metadata:
                widget.outlineViewModel.paragraphComponentViewModel.blockType !=
                        null
                    ? {
                        'blockType': widget.outlineViewModel
                            .paragraphComponentViewModel.blockType,
                      }
                    : {},
            textSelection:
                widget.outlineViewModel.paragraphComponentViewModel.selection,
            selectionColor: widget
                .outlineViewModel.paragraphComponentViewModel.selectionColor,
            highlightWhenEmpty: widget.outlineViewModel
                .paragraphComponentViewModel.highlightWhenEmpty,
            underlines: widget.outlineViewModel.paragraphComponentViewModel
                .createUnderlines(),
            textDirection: widget
                .outlineViewModel.paragraphComponentViewModel.textDirection,
            showDebugPaint: false,
          ),
        ),
        // const Text('Test'),
      ],
    );
  }
}
