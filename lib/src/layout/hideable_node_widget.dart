import 'package:flutter/material.dart';
import 'package:structured_rich_text_editor/src/document_structure/document_structure.dart';

const animationDuration = Duration(milliseconds: 150);
const animationCurve = Curves.easeInOut;

class HideableNodeWidget extends StatefulWidget {
  const HideableNodeWidget({
    required this.treeNode,
    required this.components,
    required this.childNodeWidgets,
    this.onFoldingStart,
    this.onFoldingEnd,
    this.onUnfoldingStart,
    this.onUnfoldingEnd,
    super.key,
  });

  final DocumentStructureTreeNode treeNode;
  final List<Widget> components;
  final List<Widget> childNodeWidgets;
  final VoidCallback? onFoldingStart;
  final VoidCallback? onFoldingEnd;
  final VoidCallback? onUnfoldingStart;
  final VoidCallback? onUnfoldingEnd;

  @override
  State<HideableNodeWidget> createState() => _HideableNodeWidgetState();
}

class _HideableNodeWidgetState extends State<HideableNodeWidget> {
  bool _animationRunning = false;
  bool _isUnfolded = true;

  @override
  void initState() {
    super.initState();
    _isUnfolded = true;
    _animationRunning = false;
  }

  void toggleFoldChildren() {
    if (_isUnfolded) {
      if (widget.onFoldingStart != null) widget.onFoldingStart!();
    } else {
      if (widget.onUnfoldingStart != null) widget.onUnfoldingStart!();
    }
    setState(() {
      _isUnfolded = !_isUnfolded;
      _animationRunning = true;
    });
  }

  void foldChildren() {
    if (_isUnfolded) toggleFoldChildren();
  }

  void unfoldChildren() {
    if (!_isUnfolded) toggleFoldChildren();
  }

  @override
  Widget build(BuildContext context) {
    // das hier noch mit Einklapp-Widget umgeben
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: toggleFoldChildren,
          child: SizedBox(
            width: 30.0,
            height: 40.0,
            child: widget.childNodeWidgets.isNotEmpty
                ? AnimatedRotation(
                    key: ValueKey<String>(widget.treeNode.id),
                    turns: _isUnfolded ? 0.25 : 0.0,
                    duration: animationDuration,
                    curve: animationCurve,
                    child: const Icon(Icons.arrow_right),
                  )
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.components,
              if (_isUnfolded || _animationRunning)
                ClipRect(
                  child: AnimatedOpacity(
                    opacity: _isUnfolded ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedSlide(
                      offset: Offset(0, _isUnfolded ? 0 : -1),
                      duration: const Duration(milliseconds: 250),
                      onEnd: () {
                        setState(() {
                          _animationRunning = false;
                        });
                        if (_isUnfolded) {
                          if (widget.onUnfoldingEnd != null) {
                            widget.onUnfoldingEnd!();
                          }
                        } else {
                          if (widget.onFoldingEnd != null) {
                            widget.onFoldingEnd!();
                          }
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.childNodeWidgets,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
