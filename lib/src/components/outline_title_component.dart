import 'package:flutter/widgets.dart';
import 'package:outline_editor/src/components/collapse_expand_button.dart';
import 'package:outline_editor/src/components/outline_component_base.dart';
import 'package:outline_editor/src/outline_document/outline_document.dart';
import 'package:outline_editor/src/outline_editor/attributions.dart';
import 'package:super_editor/super_editor.dart';

class TitleNode extends TextNode {
  TitleNode({
    required super.id,
    required super.text,
    Map<String, dynamic>? metadata,
  }) : super(metadata: {
          ...metadata ?? {},
          "blockType": titleAttribution,
        }) {
    // if (getMetadataValue("blockType") == null) {
    //   putMetadataValue("blockType", titleAttribution);
    // }
  }

  @override
  TextNode copy() {
    return TitleNode(
        id: id, text: text.copyText(0), metadata: Map.from(metadata));
  }

  @override
  TextNode copyTextNodeWith({
    String? id,
    AttributedText? text,
    Map<String, dynamic>? metadata,
  }) {
    return TitleNode(
      id: id ?? this.id,
      text: text ?? this.text,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || super == other && other is TitleNode;
    // bisher noch kein Unterschied zu TextNode
    // && other is TitleNode && runtimeType == other.runtimeType && ......;
  }

  // stub, noch überlüssig
  @override
  int get hashCode => super.hashCode;
}

class OutlineTitleComponentViewModel extends OutlineComponentViewModel
    with TextComponentViewModel {
  OutlineTitleComponentViewModel({
    required super.nodeId,
    required this.outlineIndentLevel,
    required this.indexInChildren,
    this.isCollapsed = false,
    this.isVisible = true,
    this.hasChildren = false,
    this.highlightWhenEmpty = false,
    this.selection,
    this.inlineWidgetBuilders = const [],
    required this.selectionColor,
    required this.text,
    required this.textAlignment,
    required this.textDirection,
    required this.textStyleBuilder,
  });

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
  bool highlightWhenEmpty;
  @override
  TextSelection? selection;
  @override
  Color selectionColor;
  @override
  AttributedText text;
  @override
  TextAlign textAlignment;
  @override
  TextDirection textDirection;
  @override
  AttributionStyleBuilder textStyleBuilder;

  @override
  @override
  SingleColumnLayoutComponentViewModel copy() {
    return OutlineTitleComponentViewModel(
      nodeId: nodeId,
      outlineIndentLevel: outlineIndentLevel,
      indexInChildren: indexInChildren,
      isVisible: isVisible,
      hasChildren: hasChildren,
      isCollapsed: isCollapsed,
      selectionColor: selectionColor,
      text: text,
      textAlignment: textAlignment,
      textDirection: textDirection,
      textStyleBuilder: textStyleBuilder,
      highlightWhenEmpty: highlightWhenEmpty,
      selection: selection,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is OutlineTitleComponentViewModel &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId &&
          outlineIndentLevel == other.outlineIndentLevel &&
          isVisible == other.isVisible &&
          hasChildren == other.hasChildren &&
          isCollapsed == other.isCollapsed &&
          highlightWhenEmpty == other.highlightWhenEmpty &&
          selection == other.selection &&
          selectionColor == other.selectionColor &&
          text == other.text &&
          textAlignment == other.textAlignment &&
          textDirection == other.textDirection &&
          textStyleBuilder == other.textStyleBuilder;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      outlineIndentLevel.hashCode ^
      isVisible.hashCode ^
      hasChildren.hashCode ^
      isCollapsed.hashCode ^
      highlightWhenEmpty.hashCode ^
      selection.hashCode ^
      selectionColor.hashCode ^
      text.hashCode ^
      textAlignment.hashCode ^
      textDirection.hashCode ^
      textStyleBuilder.hashCode;
}

class OutlineTitleComponentBuilder implements ComponentBuilder {
  const OutlineTitleComponentBuilder({
    required this.editor,
    this.leadingControlsBuilder,
    this.topControlsBuilder,
  });

  final Editor editor;
  final SideControlsBuilder? leadingControlsBuilder;
  final TopControlsBuilder? topControlsBuilder;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    if (node is! TitleNode) {
      return null;
    }
    assert(
        document is OutlineDocument,
        'createViewModel needs a '
        'StructuredDocument, but ${document.runtimeType} was given');

    final outlineDoc = document as OutlineDocument;
    final textDirection = getParagraphDirection(node.text.toPlainText());

    return OutlineTitleComponentViewModel(
      nodeId: node.id,
      outlineIndentLevel: outlineDoc.getTreenodeDepth(node.id),
      indexInChildren: outlineDoc.getIndexInChildren(node.id),
      hasChildren: outlineDoc
          .getOutlineTreenodeForDocumentNodeId(node.id)
          .children
          .isNotEmpty,
      isCollapsed: outlineDoc.isCollapsed(node.id),
      isVisible: outlineDoc.isVisible(node.id),
      selectionColor: const Color(0x00000000),
      text: node.text,
      textAlignment: TextAlign.left,
      textDirection: textDirection,
      textStyleBuilder: noStyleBuilder,
    );
  }

  @override
  Widget? createComponent(SingleColumnDocumentComponentContext componentContext,
      SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! OutlineTitleComponentViewModel) {
      return null;
    }
    return OutlineTitleComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
      editor: editor,
      leadingControlsBuilder: leadingControlsBuilder ??
          (BuildContext context, int indexInChildren) {
            if (indexInChildren == 0) {
              return CollapseExpandButton(
                editor: editor,
                docNodeId: componentViewModel.nodeId,
              );
            }
            return null;
          },
      topControlsBuilder: topControlsBuilder,
    );
  }
}

class OutlineTitleComponent extends OutlineComponent {
  const OutlineTitleComponent({
    super.key,
    required this.viewModel,
    required this.editor,
    super.leadingControlsBuilder,
    super.topControlsBuilder,
    super.indentPerLevel,
    super.minimumIndent,
  }) : super(
          outlineComponentViewModel: viewModel,
        );

  final OutlineTitleComponentViewModel viewModel;
  final Editor editor;

  @override
  State createState() => _OutlineTitleComponentState();
}

class _OutlineTitleComponentState
    extends OutlineComponentState<OutlineTitleComponent>
    with ProxyDocumentComponent<OutlineTitleComponent>, ProxyTextComposable {
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
      text: widget.viewModel.text,
      textStyleBuilder: widget.viewModel.textStyleBuilder,
      textAlign: widget.viewModel.textAlignment,
      metadata: {
        'blockType': NamedAttribution('title'),
      },
      textSelection: widget.viewModel.selection,
      selectionColor: widget.viewModel.selectionColor,
      highlightWhenEmpty: widget.viewModel.highlightWhenEmpty,
      underlines: widget.viewModel.createUnderlines(),
      textDirection: widget.viewModel.textDirection,
      showDebugPaint: false,
    );
  }

  // @override
  // Widget? buildTopControls(BuildContext context) {
  //   if (widget.topControlsBuilder == null) {
  //     return null;
  //   } else {
  //     return widget.topControlsBuilder!(
  //       context,
  //     );
  //   }
  // }

  // @override
  // Widget? buildLeadingControls(BuildContext context, int indexInChildren) {
  //   if (indexInChildren == 0) {
  //     return CollapseExpandButton(
  //       editor: widget.editor,
  //       docNodeId: widget.viewModel.nodeId,
  //     );
  //   }
  //   return null;
  // }
}
