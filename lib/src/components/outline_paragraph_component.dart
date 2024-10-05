import 'package:flutter/material.dart';
import 'package:outline_editor/src/components/component_animations.dart';
import 'package:outline_editor/src/components/outline_component_mixin.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineParagraphComponentViewModel
    extends SingleColumnLayoutComponentViewModel
    with TextComponentViewModel, OutlineComponentViewModel {
  OutlineParagraphComponentViewModel({
    required super.nodeId,
    required this.paragraphComponentViewModel,
    required this.outlineIndentLevel,
    this.isCollapsed = false, // FIXME: sollte nur in Title implementiert werden
    this.isVisible = true,
    this.hasChildren = false,
    super.padding = EdgeInsets.zero,
  });

  final ParagraphComponentViewModel paragraphComponentViewModel;
  @override
  int outlineIndentLevel;
  @override
  bool isVisible;
  @override
  bool hasChildren;
  bool isCollapsed;

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
      outlineIndentLevel: outlineIndentLevel,
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
          outlineIndentLevel == other.outlineIndentLevel &&
          isVisible == other.isVisible &&
          hasChildren == other.hasChildren &&
          padding == other.padding &&
          outlineIndentLevel == other.outlineIndentLevel &&
          isCollapsed == other.isCollapsed &&
          isVisible == other.isVisible &&
          hasChildren == other.hasChildren;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      paragraphComponentViewModel.hashCode ^
      outlineIndentLevel.hashCode ^
      isVisible.hashCode ^
      hasChildren.hashCode ^
      padding.hashCode ^
      outlineIndentLevel.hashCode ^
      isCollapsed.hashCode ^
      isVisible.hashCode ^
      hasChildren.hashCode;

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
        document is OutlineDocument,
        'createViewModel needs a '
        'StructuredDocument, but ${document.runtimeType} was given');

    final paragraphViewModel = const ParagraphComponentBuilder()
        .createViewModel(document, node) as ParagraphComponentViewModel;
    return OutlineParagraphComponentViewModel(
      nodeId: node.id,
      paragraphComponentViewModel: paragraphViewModel,
      outlineIndentLevel:
          (document as OutlineDocument).getIndentationLevel(node.id),
      hasChildren: (document as OutlineDocument)
          .getTreeNodeForDocumentNode(node.id)
          .children
          .isNotEmpty,
      isCollapsed: false, // ############NEIN. Warum kriege ich hier nicht den Kontext des Editors?
    );
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    assert(componentViewModel is OutlineParagraphComponentViewModel,
        "componentViewModel is no OutlineParagraphComponentViewModel but a ${componentViewModel.runtimeType}");
    return OutlineParagraphComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel as OutlineParagraphComponentViewModel,
    );
  }
}

class OutlineParagraphComponent extends OutlineComponent {
  const OutlineParagraphComponent({
    super.key,
    required this.viewModel,
  }) : super(outlineComponentViewModel: viewModel);

  final OutlineParagraphComponentViewModel viewModel;

  @override
  State createState() => _OutlineParagraphComponentState();
}

class _OutlineParagraphComponentState extends State<OutlineParagraphComponent>
    with
        ProxyDocumentComponent<OutlineParagraphComponent>,
        ProxyTextComposable,
        OutlineComponentState {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable =>
      childDocumentComponentKey.currentState as TextComposable;

  @override
  Widget buildWrappedComponent(BuildContext context) {
    return TextComponent(
      key: _textKey,
      text: widget.viewModel.paragraphComponentViewModel.text,
      textStyleBuilder:
          widget.viewModel.paragraphComponentViewModel.textStyleBuilder,
      textScaler: widget.viewModel.paragraphComponentViewModel.textScaler,
      textAlign: widget.viewModel.paragraphComponentViewModel.textAlignment,
      metadata: widget.viewModel.paragraphComponentViewModel.blockType != null
          ? {
              'blockType':
                  widget.viewModel.paragraphComponentViewModel.blockType,
            }
          : {},
      textSelection: widget.viewModel.paragraphComponentViewModel.selection,
      selectionColor:
          widget.viewModel.paragraphComponentViewModel.selectionColor,
      highlightWhenEmpty:
          widget.viewModel.paragraphComponentViewModel.highlightWhenEmpty,
      underlines:
          widget.viewModel.paragraphComponentViewModel.createUnderlines(),
      textDirection: widget.viewModel.paragraphComponentViewModel.textDirection,
      showDebugPaint: false,
    );
  }

  @override
  Widget? buildControls(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {}, // toggleFoldChildren,
      child: SizedBox(
        width: indentPerLevel, // widget.horizontalChildOffset,
        height: 28, //widget.foldControlHeight,
        child: widget.viewModel.hasChildren
            ? AnimatedRotation(
                // key: ValueKey<String>(widget.treeNode.id),
                turns: widget.viewModel.isCollapsed ? 0.0 : 0.25,
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
    );
  }
}
