import 'package:flutter/material.dart';
import 'package:outline_editor/src/components/component_animations.dart';
import 'package:outline_editor/src/components/outline_component_mixins.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineParagraphComponentViewModel
    extends OutlineComponentViewModel<ParagraphComponentViewModel>
    with TextComponentViewModel {
  OutlineParagraphComponentViewModel({
    required super.nodeId,
    required super.wrappedViewModel,
    required super.outlineIndentLevel,
    super.hasChildren = false,
    super.isVisible = true,
    super.isCollapsed = false,
    super.padding = EdgeInsets.zero,
  });

  @override
  OutlineParagraphComponentViewModel copy() {
    return OutlineParagraphComponentViewModel(
      nodeId: nodeId,
      wrappedViewModel: wrappedViewModel.copy(),
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
          wrappedViewModel == other.wrappedViewModel &&
          outlineIndentLevel == other.outlineIndentLevel &&
          isVisible == other.isVisible &&
          padding == other.padding &&
          hasChildren == other.hasChildren;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      wrappedViewModel.hashCode ^
      outlineIndentLevel.hashCode ^
      isVisible.hashCode ^
      padding.hashCode ^
      hasChildren.hashCode;

  @override
  set highlightWhenEmpty(bool highlight) =>
      wrappedViewModel.highlightWhenEmpty = highlight;

  @override
  set selection(TextSelection? selection) =>
      wrappedViewModel.selection = selection;

  @override
  set selectionColor(Color color) =>
      wrappedViewModel.selectionColor = color;

  @override
  set text(AttributedText text) => wrappedViewModel.text = text;

  @override
  set textAlignment(TextAlign alignment) =>
      wrappedViewModel.textAlignment = alignment;

  @override
  set textDirection(TextDirection direction) =>
      wrappedViewModel.textDirection = direction;

  @override
  set textStyleBuilder(AttributionStyleBuilder styleBuilder) =>
      wrappedViewModel.textStyleBuilder = styleBuilder;

  @override
  bool get highlightWhenEmpty => wrappedViewModel.highlightWhenEmpty;

  @override
  TextSelection? get selection => wrappedViewModel.selection;

  @override
  Color get selectionColor => wrappedViewModel.selectionColor;

  @override
  AttributedText get text => wrappedViewModel.text;

  @override
  TextAlign get textAlignment => wrappedViewModel.textAlignment;

  @override
  TextDirection get textDirection => wrappedViewModel.textDirection;

  @override
  AttributionStyleBuilder get textStyleBuilder =>
      wrappedViewModel.textStyleBuilder;
}

class OutlineParagraphComponentBuilder with OutlineComponentBuilder<ParagraphComponentViewModel> {
  const OutlineParagraphComponentBuilder();

  @override
  ParagraphComponentViewModel createWrappedViewModel(
      Document document, DocumentNode node) {
    return const ParagraphComponentBuilder()
        .createViewModel(document, node) as ParagraphComponentViewModel;
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    assert(componentViewModel is OutlineComponentViewModel<ParagraphComponentViewModel>);
    return OutlineParagraphComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel as OutlineComponentViewModel<ParagraphComponentViewModel>,
    );
  }
}

class OutlineParagraphComponent extends OutlineComponent<ParagraphComponentViewModel> {
  const OutlineParagraphComponent({
    super.key,
    required super.viewModel,
  });

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
      text: widget.viewModel.wrappedViewModel.text,
      textStyleBuilder:
          widget.viewModel.wrappedViewModel.textStyleBuilder,
      textScaler: widget.viewModel.wrappedViewModel.textScaler,
      textAlign: widget.viewModel.wrappedViewModel.textAlignment,
      metadata: widget.viewModel.wrappedViewModel.blockType != null
          ? {
              'blockType':
                  widget.viewModel.wrappedViewModel.blockType,
            }
          : {},
      textSelection: widget.viewModel.wrappedViewModel.selection,
      selectionColor:
          widget.viewModel.wrappedViewModel.selectionColor,
      highlightWhenEmpty:
          widget.viewModel.wrappedViewModel.highlightWhenEmpty,
      underlines:
          widget.viewModel.wrappedViewModel.createUnderlines(),
      textDirection: widget.viewModel.wrappedViewModel.textDirection,
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
                // key: ValueKey<String>(widget.viewModel.treeNode.id),
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
