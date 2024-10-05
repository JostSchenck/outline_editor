import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:outline_editor/outline_editor.dart';

const double indentPerLevel = 30;

mixin OutlineComponentViewModel on SingleColumnLayoutComponentViewModel {
  int get outlineIndentLevel;

  set outlineIndentLevel(int indentLevel);

  bool get isVisible;

  set isVisible(bool isVisible);

  bool get hasChildren;

  set hasChildren(bool hasChildren);
}

/// Components to be used in an outline editor extend this class that is
/// passed an OutlineComponentViewModel (usually their own view model) that
/// gives information on folding state and indent.
abstract class OutlineComponent extends StatefulWidget {
  const OutlineComponent({super.key, required this.outlineComponentViewModel});

  final OutlineComponentViewModel outlineComponentViewModel;
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
      // mainAxisSize: MainAxisSize.min,
      children: [
        // Indent on start side
        SizedBox(
          width: indentPerLevel *
              (widget.outlineComponentViewModel.outlineIndentLevel.toDouble() +
                  1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (controls != null) controls,
            ],
          ),
        ),

        // GestureDetector(
        //   behavior: HitTestBehavior.translucent,
        //   onTap: () {}, // toggleFoldChildren,
        //   child: SizedBox(
        //     width: 30, // widget.horizontalChildOffset,
        //     height: 20, //widget.foldControlHeight,
        //     child: widget.outlineComponentViewModel.hasChildren
        //         ? const AnimatedRotation(
        //             // key: ValueKey<String>(widget.treeNode.id),
        //             turns: 0.0, // _isFolded ? 0.0 : 0.25,
        //             duration: animationDuration,
        //             curve: animationCurve,
        //             child: Icon(
        //               Icons.arrow_right,
        //               size: 28,
        //               color: Color(0xFF999999),
        //             ),
        //           )
        //         : const Icon(
        //             Icons.horizontal_rule,
        //             size: 14,
        //             color: Color(0xFFB5B6B7),
        //           ),
        //   ),
        // ),
        // widget.componentBuilder.createComponent(),
        Expanded(
          child: buildWrappedComponent(context),
        ),
      ],
    );
  }
}
