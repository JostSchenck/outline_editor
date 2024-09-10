import 'package:flutter/material.dart';
import 'package:structured_rich_text_editor/src/document_structure/document_structure.dart';
import 'package:structured_rich_text_editor/src/folding_state/document_folding_state.dart';
import 'package:super_editor/super_editor.dart';

const animationDuration = Duration(milliseconds: 150);
const animationCurve = Curves.easeInOut;

class HideableNodeWidget extends StatefulWidget {
  const HideableNodeWidget({
    required this.treeNode,
    required this.components,
    required this.childNodeWidgets,
    required this.context,
    required this.foldControlHeight,
    required this.horizontalChildOffset,
    this.onFoldingStart,
    this.onFoldingEnd,
    this.onUnfoldingStart,
    this.onUnfoldingEnd,
    super.key,
  });

  final DocumentStructureTreeNode treeNode;
  final EditContext context;
  final List<Widget> components;
  final List<Widget> childNodeWidgets;
  final VoidCallback? onFoldingStart;
  final VoidCallback? onFoldingEnd;
  final VoidCallback? onUnfoldingStart;
  final VoidCallback? onUnfoldingEnd;
  final double foldControlHeight;
  final double horizontalChildOffset;

  @override
  State<HideableNodeWidget> createState() => _HideableNodeWidgetState();
}

class _HideableNodeWidgetState extends State<HideableNodeWidget> {
  bool _animationRunning = false;
  bool _isFolded = false;

  @override
  void initState() {
    super.initState();
    _isFolded = false;
    _animationRunning = false;
  }

  void structureChangeListener() {
    // TODOs
  }

  void toggleFoldChildren() {
    if (_isFolded) {
      if (widget.onUnfoldingStart != null) widget.onUnfoldingStart!();
    } else {
      if (widget.onFoldingStart != null) widget.onFoldingStart!();
    }
    setState(() {
      _isFolded = !_isFolded;
      _animationRunning = true;
      widget.context.foldingState
          .setTreeNodeFoldingState(widget.treeNode.id, _isFolded);
    });
  }

  void foldChildren() {
    if (!_isFolded) toggleFoldChildren();
  }

  void unfoldChildren() {
    if (_isFolded) toggleFoldChildren();
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
            width: widget.horizontalChildOffset,
            height: widget.foldControlHeight,
            child: widget.childNodeWidgets.isNotEmpty
                ? AnimatedRotation(
                    key: ValueKey<String>(widget.treeNode.id),
                    turns: _isFolded ? 0.0 : 0.25,
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
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...(widget.components),
            if (!_isFolded || _animationRunning)
              ClipRect(
                child: AnimatedOpacity(
                  opacity: _isFolded ? 0 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedSlide(
                    offset: Offset(0, _isFolded ? -1 : 0),
                    duration: const Duration(milliseconds: 250),
                    onEnd: () {
                      setState(() {
                        _animationRunning = false;
                      });
                      if (_isFolded) {
                        if (widget.onFoldingEnd != null) {
                          widget.onFoldingEnd!();
                        }
                      } else {
                        if (widget.onUnfoldingEnd != null) {
                          widget.onUnfoldingEnd!();
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
      ],
    );
  }
}
