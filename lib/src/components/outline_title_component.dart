import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:outline_editor/src/components/collapse_expand_button.dart';
import 'package:outline_editor/src/components/outline_component_base.dart';
import 'package:outline_editor/src/outline_document/outline_document.dart';
import 'package:outline_editor/src/outline_editor/attributions.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_text_layout/super_text_layout.dart';

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

  // @override
  // bool operator ==(Object other) {
  //   return identical(this, other) || super == other && other is TitleNode;
  //   // bisher noch kein Unterschied zu TextNode
  //   // && other is TitleNode && runtimeType == other.runtimeType && ......;
  // }
  //
  // // stub, noch überlüssig
  // @override
  // int get hashCode => super.hashCode;
}

typedef TrailingWidgetsBuilder = Widget? Function(
    BuildContext context, Editor editor, String nodeId, double lineHeight);

class OutlineTitleComponentViewModel extends OutlineComponentViewModel
    with TextComponentViewModel {
  OutlineTitleComponentViewModel({
    required super.nodeId,
    required super.createdAt,
    required this.outlineIndentLevel,
    required this.indexInChildren,
    this.isCollapsed = false,
    this.isVisible = true,
    this.hasChildren = false,
    this.highlightWhenEmpty = false,
    this.selection,
    this.inlineWidgetBuilders = const [],
    this.trailingWidgetsBuilder,
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
  TrailingWidgetsBuilder? trailingWidgetsBuilder;

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
      createdAt: DateTime.now(),
      outlineIndentLevel: outlineIndentLevel,
      indexInChildren: indexInChildren,
      inlineWidgetBuilders: inlineWidgetBuilders,
      trailingWidgetsBuilder: trailingWidgetsBuilder,
      isVisible: isVisible,
      hasChildren: hasChildren,
      isCollapsed: isCollapsed,
      selection: selection,
      selectionColor: selectionColor,
      text: text,
      textAlignment: textAlignment,
      textDirection: textDirection,
      textStyleBuilder: textStyleBuilder,
      highlightWhenEmpty: highlightWhenEmpty,
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
          indexInChildren == other.indexInChildren &&
          inlineWidgetBuilders.equals(other.inlineWidgetBuilders) &&
          trailingWidgetsBuilder == other.trailingWidgetsBuilder &&
          isVisible == other.isVisible &&
          hasChildren == other.hasChildren &&
          isCollapsed == other.isCollapsed &&
          selection == other.selection &&
          selectionColor == other.selectionColor &&
          text == other.text &&
          textAlignment == other.textAlignment &&
          textDirection == other.textDirection &&
          textStyleBuilder == other.textStyleBuilder &&
          highlightWhenEmpty == other.highlightWhenEmpty;

  @override
  int get hashCode =>
      super.hashCode ^
      nodeId.hashCode ^
      outlineIndentLevel.hashCode ^
      indexInChildren.hashCode ^
      inlineWidgetBuilders.hashCode ^
      trailingWidgetsBuilder.hashCode ^
      isVisible.hashCode ^
      hasChildren.hashCode ^
      isCollapsed.hashCode ^
      selection.hashCode ^
      selectionColor.hashCode ^
      text.hashCode ^
      textAlignment.hashCode ^
      textDirection.hashCode ^
      textStyleBuilder.hashCode ^
      highlightWhenEmpty.hashCode;
}

class OutlineTitleComponentBuilder implements ComponentBuilder {
  const OutlineTitleComponentBuilder({
    required this.editor,
    this.leadingControlsBuilder,
    this.topControlsBuilder,
    this.inlineWidgetBuilders,
    this.trailingWidgetsBuilder,
  });

  final Editor editor;
  final SideControlsBuilder? leadingControlsBuilder;
  final TopControlsBuilder? topControlsBuilder;
  final InlineWidgetBuilderChain? inlineWidgetBuilders;
  final TrailingWidgetsBuilder? trailingWidgetsBuilder;

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
      createdAt: DateTime.now(),
      outlineIndentLevel: outlineDoc.getTreenodeDepth(node.id),
      inlineWidgetBuilders: inlineWidgetBuilders ?? [],
      trailingWidgetsBuilder: trailingWidgetsBuilder,
      indexInChildren: outlineDoc.getIndexInChildren(node.id),
      hasChildren: outlineDoc
          .getTreenodeForDocumentNodeId(node.id)
          .treenode
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
    final globalKey = GlobalKey<OutlineTitleComponentState>();
    return OutlineTitleComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
      editor: editor,
      globalKey: globalKey,
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
      trailingWidgetsBuilder: trailingWidgetsBuilder,
    );
  }
}

class OutlineTitleComponent extends OutlineComponent {
  const OutlineTitleComponent({
    super.key,
    required this.viewModel,
    required super.editor,
    required super.globalKey,
    this.trailingWidgetsBuilder,
    super.leadingControlsBuilder,
    super.topControlsBuilder,
    super.indentPerLevel,
    super.minimumIndent,
  }) : super(
          outlineComponentViewModel: viewModel,
        );

  final OutlineTitleComponentViewModel viewModel;
  final TrailingWidgetsBuilder? trailingWidgetsBuilder;

  @override
  State createState() => OutlineTitleComponentState();
}

class OutlineTitleComponentState
    extends OutlineComponentState<OutlineTitleComponent>
    with
        ProxyDocumentComponent<OutlineTitleComponent>,
        ProxyTextComposable,
        ProseTextBlock {
  final _textKey =
      GlobalKey(debugLabel: '_OutlineTitleComponentState._textKey');

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  ProseTextLayout get textLayout =>
      // FIXME: this is @visibleForTesting only --> how to legally retrieve textLayout?
      (_textKey.currentState as TextComponentState).textLayout;

  @override
  TextComposable get childTextComposable =>
      childDocumentComponentKey.currentState as TextComposable;

  @override
  Widget buildWrappedComponent(BuildContext context) {
    final textComponent = TextComponent(
      key: _textKey,
      text: widget.viewModel.text,
      textStyleBuilder: widget.viewModel.textStyleBuilder,
      inlineWidgetBuilders: widget.viewModel.inlineWidgetBuilders,
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
    final trailingBuilder = widget.viewModel.trailingWidgetsBuilder;
    if (trailingBuilder == null) {
      return textComponent;
    }
    return LayoutBuilder(builder: (context, constraints) {
      return _TextWithTrailing(
        textKey: _textKey,
        textComponent: textComponent,
        trailingBuilder: trailingBuilder,
        maxTrailingWidth: constraints.maxWidth * 0.5,
        editor: widget.editor,
        nodeId: widget.viewModel.nodeId,
      );
    });
  }
}

class _TextWithTrailing extends StatefulWidget {
  const _TextWithTrailing({
    required this.textKey,
    required this.textComponent,
    required this.trailingBuilder,
    required this.maxTrailingWidth,
    required this.editor,
    required this.nodeId,
  });

  final GlobalKey textKey;
  final Widget textComponent;
  final TrailingWidgetsBuilder trailingBuilder;
  final double maxTrailingWidth;
  final Editor editor;
  final String nodeId;

  @override
  State<_TextWithTrailing> createState() => _TextWithTrailingState();
}

class _TextWithTrailingState extends State<_TextWithTrailing> {
  double? lineHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = widget.textKey.currentState;
      if (state is TextComponentState) {
        final height =
            state.textLayout.getLineHeightAtPosition(TextPosition(offset: 0));
        if (mounted) {
          setState(() {
            lineHeight = height;
          });
        }
      } else {
        debugPrint('TextComponentState not yet ready');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: widget.textComponent),
        const SizedBox(width: 8),
        SizedBox(
          // ConstrainedBox(
          // constraints: BoxConstraints(
          //   maxWidth: widget.maxTrailingWidth,
          // ),
          child: lineHeight == null
              ? const SizedBox(
                  height: 30,
                  width: 30,
                  child: ColoredBox(color: Color(0xFFFF0000)))
              : widget.trailingBuilder(
                  context,
                  widget.editor,
                  widget.nodeId,
                  lineHeight!,
                ),
        ),
      ],
    );
  }
}
