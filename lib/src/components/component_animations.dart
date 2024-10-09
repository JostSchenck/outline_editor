import 'package:flutter/widgets.dart';

const animationDuration = Duration(milliseconds: 150);
const animationCurve = Curves.easeInOut;

// adapted from https://stackoverflow.com/questions/66640920/how-do-you-animate-to-expand-a-container-from-0-height-to-the-height-of-its-cont
// answer by IcyIcicle
class AnimatedVisibility extends StatefulWidget {
  const AnimatedVisibility({
    super.key,
    this.child,
    required this.visible,
    this.axis = Axis.vertical,
    this.axisAlignment = 0.0,
    this.curve = animationCurve,
    this.duration = animationDuration,
    this.reverseDuration,
  });
  
  final Widget? child;

  /// Show or hide the child
  final bool visible;

  /// See [SizeTransition]
  final Axis axis;

  /// See [SizeTransition]
  final double axisAlignment;
  final Curve curve;
  final Duration duration;
  final Duration? reverseDuration;

  @override
  AnimatedVisibilityState createState() => AnimatedVisibilityState();
}

class AnimatedVisibilityState extends State<AnimatedVisibility> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axis: widget.axis,
      axisAlignment: widget.axisAlignment,
      child: widget.child,
    );
  }
}