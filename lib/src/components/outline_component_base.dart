import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/components/component_animations.dart';

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

typedef SideControlsBuilder = Widget? Function(
    BuildContext context, int indexInChildren);
typedef TopControlsBuilder = Widget? Function(BuildContext context);

/// Components to be used in an outline editor extend this class that is
/// passed an OutlineComponentViewModel (usually their own view model) that
/// gives information on folding state and indent.
abstract class OutlineComponent extends StatefulWidget {
  const OutlineComponent({
    super.key,
    required this.outlineComponentViewModel,
    this.leadingControlsBuilder,
    this.topControlsBuilder,
    this.indentPerLevel = 30,
    this.minimumIndent = 0,
  });

  final OutlineComponentViewModel outlineComponentViewModel;
  final SideControlsBuilder? leadingControlsBuilder;
  final TopControlsBuilder? topControlsBuilder;
  final double indentPerLevel;
  final double minimumIndent;
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

  double _indentWidth() =>
      widget.minimumIndent +
      widget.indentPerLevel *
          (widget.outlineComponentViewModel.outlineIndentLevel.toDouble() + 1);

  // this must not be overridden by components using this mixin
  @override
  Widget build(BuildContext context) {
    final leadingControls = widget.leadingControlsBuilder != null
        ? widget.leadingControlsBuilder!(
            context, widget.outlineComponentViewModel.indexInChildren)
        : null;
    final topControls = widget.topControlsBuilder != null
        ? widget.topControlsBuilder!(context)
        : null;
    // final trailingControls = buildTrailingControls(
    //     context, widget.outlineComponentViewModel.indexInChildren);
    return AnimatedVisibility(
      visible: widget.outlineComponentViewModel.isVisible,
      axis: Axis.vertical,
      child: Column(
        children: [
          if (topControls != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _indentWidth(),
                ),
                Expanded(child: topControls),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            // mainAxisSize: MainAxisSize.min,
            children: [
              // Indent on start side
              SizedBox(
                width: _indentWidth(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leadingControls != null) leadingControls,
                  ],
                ),
              ),
              Expanded(
                child: buildWrappedComponent(context),
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     if (trailingControls != null) trailingControls,
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
