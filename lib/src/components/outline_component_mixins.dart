import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:outline_editor/outline_editor.dart';

const double indentPerLevel = 30;
//
// /// Mixin for all [SingleColumnLayoutComponentViewModel]s that should
// /// work in an outline; it adds information like indent level, visibility
// /// and existence of children.
// mixin OutlineComponentViewModel on SingleColumnLayoutComponentViewModel {
//   int get outlineIndentLevel;
//
//   set outlineIndentLevel(int indentLevel);
//
//   bool get isVisible;
//
//   set isVisible(bool isVisible);
//
//   bool get hasChildren;
//
//   set hasChildren(bool hasChildren);
// }

class OutlineComponentViewModel<T extends SingleColumnLayoutComponentViewModel>
    extends SingleColumnLayoutComponentViewModel {
  OutlineComponentViewModel({
    required super.nodeId,
    super.padding = EdgeInsets.zero,
    required this.wrappedViewModel,
    required this.outlineIndentLevel,
    required this.isVisible,
    required this.isCollapsed,
    required this.hasChildren,
  });

  final T wrappedViewModel;

  int outlineIndentLevel;
  bool isVisible;
  bool isCollapsed;
  bool hasChildren;

  @override
  SingleColumnLayoutComponentViewModel copy() {
    return OutlineComponentViewModel<T>(
      nodeId: nodeId,
      padding: padding,
      wrappedViewModel: wrappedViewModel.copy() as T,
      outlineIndentLevel: outlineIndentLevel,
      isVisible: isVisible,
      isCollapsed: false,
      // FIXME implement
      hasChildren: hasChildren,
    );
  }
}

/// mixin for [ComponentBuilder]s that
mixin OutlineComponentBuilder<T extends SingleColumnLayoutComponentViewModel>
    implements ComponentBuilder {
  /// Extending classes should override this method to create only the
  /// view model of the component that they intend to wrap into
  /// outline functionality.
  T createWrappedViewModel(Document document, DocumentNode node);

  /// this must not be overridden, override createWrappedViewModel instead
  @override
  SingleColumnLayoutComponentViewModel? createViewModel(
      Document document, DocumentNode node) {
    assert(
        document is OutlineDocument,
        'createViewModel needs a '
        'StructuredDocument, but ${document.runtimeType} was given');
    final outlineDoc = document as OutlineDocument;
    final wrappedViewModel = createWrappedViewModel(document, node);
    return OutlineComponentViewModel<T>(
      nodeId: node.id,
      wrappedViewModel: wrappedViewModel,
      outlineIndentLevel: outlineDoc.getIndentationLevel(node.id),
      isVisible: true,
      // FIXME get from OutlineDocument
      isCollapsed: false,
      // FIXME implement
      hasChildren:
          outlineDoc.getTreeNodeForDocumentNode(node.id).children.isNotEmpty,
    );
  }
}

/// Components to be used in an outline editor extend this class that is
/// passed an OutlineComponentViewModel (usually their own view model) that
/// gives information on folding state and indent.
abstract class OutlineComponent<T extends SingleColumnLayoutComponentViewModel>
    extends StatefulWidget {
  const OutlineComponent({super.key, required this.viewModel});

  final OutlineComponentViewModel<T> viewModel;
}

/// Mixin to be used by component state classes for classes derived from
/// OutlineComponent. This mixin provides its own build method which must not
/// be overridden; instead, extending components override at least
/// `buildWrappedComponent`.
mixin OutlineComponentState<T extends OutlineComponent> on State<T> {
  /// Builds a component that is to be wrapped in outline stuff by this mixin.
  /// Components using this mixin must return here only the component itself,
  /// instead of overriding `build`.
  Widget buildWrappedComponent(BuildContext context);

  /// Builds control widgets that are to be shown to the left of the component.
  /// If this is not overridden or null returned, no controls will be shown.
  Widget? buildControls(BuildContext context) => null;

  // this must not be overridden by components using this mixin
  @override
  Widget build(BuildContext context) {
    final controls = buildControls(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indent on start side
        SizedBox(
          width: indentPerLevel * (widget.viewModel.outlineIndentLevel.toDouble() + 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (controls != null) controls,
            ],
          ),
        ),

        Expanded(
          child: buildWrappedComponent(context),
        ),
      ],
    );
  }
}
