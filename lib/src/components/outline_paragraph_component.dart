import 'package:flutter/material.dart';
import 'package:outline_editor/outline_editor.dart';

class OutlineParagraphComponentViewModel extends OutlineComponentViewModel
    with TextComponentViewModel {
  OutlineParagraphComponentViewModel({
    required super.nodeId,
    required this.paragraphComponentViewModel,
    required this.outlineIndentLevel,
    required this.indexInChildren,
    this.inlineWidgetBuilders = const [],
    this.isCollapsed = false, // FIXME: sollte nur in Title implementiert werden
    this.isVisible = true,
    this.hasChildren = false,
  });

  final ParagraphComponentViewModel paragraphComponentViewModel;
  @override
  int outlineIndentLevel;
  @override
  int indexInChildren;
  @override
  bool isVisible;
  @override
  bool hasChildren;
  @override
  bool isCollapsed;
  @override
  InlineWidgetBuilderChain inlineWidgetBuilders;

  @override
  bool get highlightWhenEmpty => paragraphComponentViewModel.highlightWhenEmpty;

  @override
  set highlightWhenEmpty(bool highlight) =>
      paragraphComponentViewModel.highlightWhenEmpty = highlight;

  @override
  TextSelection? get selection => paragraphComponentViewModel.selection;

  @override
  set selection(TextSelection? selection) =>
      paragraphComponentViewModel.selection = selection;

  @override
  Color get selectionColor => paragraphComponentViewModel.selectionColor;

  @override
  set selectionColor(Color color) =>
      paragraphComponentViewModel.selectionColor = color;

  @override
  AttributedText get text => paragraphComponentViewModel.text;

  @override
  set text(AttributedText text) => paragraphComponentViewModel.text = text;

  @override
  TextAlign get textAlignment => paragraphComponentViewModel.textAlignment;

  @override
  set textAlignment(TextAlign alignment) =>
      paragraphComponentViewModel.textAlignment = alignment;

  @override
  TextDirection get textDirection => paragraphComponentViewModel.textDirection;

  @override
  set textDirection(TextDirection direction) =>
      paragraphComponentViewModel.textDirection = direction;

  @override
  AttributionStyleBuilder get textStyleBuilder =>
      paragraphComponentViewModel.textStyleBuilder;

  @override
  set textStyleBuilder(AttributionStyleBuilder styleBuilder) =>
      paragraphComponentViewModel.textStyleBuilder = styleBuilder;

  @override
  OutlineParagraphComponentViewModel copy() {
    return OutlineParagraphComponentViewModel(
      nodeId: nodeId,
      paragraphComponentViewModel: paragraphComponentViewModel.copy(),
      outlineIndentLevel: outlineIndentLevel,
      indexInChildren: indexInChildren,
      isVisible: isVisible,
      hasChildren: hasChildren,
      isCollapsed: isCollapsed,
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
          padding == other.padding &&
          isVisible == other.isVisible &&
          hasChildren == other.hasChildren &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      paragraphComponentViewModel.hashCode ^
      padding.hashCode ^
      outlineIndentLevel.hashCode ^
      isCollapsed.hashCode ^
      isVisible.hashCode ^
      hasChildren.hashCode;
}

class OutlineParagraphComponentBuilder implements ComponentBuilder {
  const OutlineParagraphComponentBuilder({
    required this.editor,
    this.leadingControlsBuilder,
    this.topControlsBuilder,
    this.hideTextGlobally = false,
  });

  final Editor editor;
  final SideControlsBuilder? leadingControlsBuilder;
  final TopControlsBuilder? topControlsBuilder;
  final bool hideTextGlobally;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    if (node is! ParagraphNode) {
      return null;
    }
    assert(
        document is OutlineDocument,
        'createViewModel needs an '
        'OutlineDocument, but ${document.runtimeType} was given');

    final paragraphViewModel = const ParagraphComponentBuilder()
        .createViewModel(document, node) as ParagraphComponentViewModel;
    final outlineDoc = document as OutlineDocument;

    return OutlineParagraphComponentViewModel(
      nodeId: node.id,
      paragraphComponentViewModel: paragraphViewModel,
      outlineIndentLevel: outlineDoc.getTreenodeDepth(node.id),
      indexInChildren: outlineDoc.getIndexInChildren(node.id),
      hasChildren: outlineDoc
          .getOutlineTreenodeForDocumentNodeId(node.id)
          .children
          .isNotEmpty,
      isCollapsed: outlineDoc.isCollapsed(node.id),
      isVisible: hideTextGlobally ? false : outlineDoc.isVisible(node.id),
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
      editor: editor,
      leadingControlsBuilder: leadingControlsBuilder ??
          (context, editor, nodeId, indexInChildren) {
            if (indexInChildren == 0) {
              return CollapseExpandButton(
                editor: editor,
                docNodeId: nodeId,
              );
            }
            return null;
          },
      topControlsBuilder: topControlsBuilder,
    );
  }
}

class OutlineParagraphComponent extends OutlineComponent {
  const OutlineParagraphComponent({
    super.key,
    required this.viewModel,
    required super.editor,
    super.leadingControlsBuilder,
    super.topControlsBuilder,
    super.indentPerLevel,
    super.minimumIndent,
  }) : super(outlineComponentViewModel: viewModel);

  final OutlineParagraphComponentViewModel viewModel;

  @override
  State createState() => _OutlineParagraphComponentState();
}

class _OutlineParagraphComponentState
    extends OutlineComponentState<OutlineParagraphComponent>
    with
        ProxyDocumentComponent<OutlineParagraphComponent>,
        ProxyTextComposable {
  final _textKey =
      GlobalKey(debugLabel: '_OutlineParagraphComponentState._textKey');

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
}
