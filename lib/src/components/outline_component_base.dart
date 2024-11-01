import 'package:flutter/widgets.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/components/component_animations.dart';

const double indentPerLevel = 30;

abstract class OutlineComponentViewModel
    extends SingleColumnLayoutComponentViewModel {
  OutlineComponentViewModel({
    required super.nodeId,
  }) : super(padding: EdgeInsets.zero);

  int get outlineIndentLevel;

  set outlineIndentLevel(int indentLevel);

  /// At which position in the parent's children or the root nodes
  /// this component is located, ie. 0 for the first child, 1 for the
  /// second, etc.
  int get indexInChildren;
  set indexInChildren(int indexInChildren);

  bool get isVisible;

  set isVisible(bool isVisible);

  bool get hasChildren;

  set hasChildren(bool hasChildren);

  bool get isCollapsed;

  set isCollapsed(bool isFolded);
}

/// Components to be used in an outline editor extend this class that is
/// passed an OutlineComponentViewModel (usually their own view model) that
/// gives information on folding state and indent.
abstract class OutlineComponent extends StatefulWidget {
  const OutlineComponent({
    super.key,
    required this.outlineComponentViewModel,
  });

  final OutlineComponentViewModel outlineComponentViewModel;
}

/// Base class for state classes for classes derived from
/// OutlineComponent. This provides its own build method which must not
/// be overridden; instead, extending components override at least
/// `buildWrappedComponent` and optionally `buildControls`.
abstract class OutlineComponentState<T extends OutlineComponent>
    extends State<T> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }

  /// Builds a component that is to be wrapped in outline stuff by this mixin.
  /// Components using this mixin must return here only the component itself,
  /// instead of overriding `build`.
  Widget buildWrappedComponent(BuildContext context);

  /// Builds control widgets that are to be shown to the left of the component.
  /// If this is not overridden or null returned, no controls will be shown.
  Widget? buildControls(BuildContext context, int indexInChildren) => null;

  // this must not be overridden by components using this mixin
  @override
  Widget build(BuildContext context) {
    final controls = buildControls(context, widget.outlineComponentViewModel.indexInChildren);
    return AnimatedVisibility(
      visible: widget.outlineComponentViewModel.isVisible,
      axis: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisSize: MainAxisSize.min,
        children: [
          // Indent on start side
          SizedBox(
            width: indentPerLevel *
                (widget.outlineComponentViewModel.outlineIndentLevel
                        .toDouble() +
                    1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (controls != null) controls,
              ],
            ),
          ),
          Expanded(
            child: buildWrappedComponent(context),
          ),
        ],
      ),
    );
  }
}

