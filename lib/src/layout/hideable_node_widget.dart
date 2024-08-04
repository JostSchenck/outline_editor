import 'package:flutter/material.dart';

class HideableNodeWidget extends StatefulWidget {
  const HideableNodeWidget({
    required this.components,
    required this.childNodeWidgets,
    super.key,
  });

  final List<Widget> components;
  final List<Widget> childNodeWidgets;

  @override
  State<HideableNodeWidget> createState() => _HideableNodeWidgetState();
}

class _HideableNodeWidgetState extends State<HideableNodeWidget> {
  @override
  Widget build(BuildContext context) {
    // das hier noch mit Einklapp-Widget umgeben
    return Column(
      children: [
        ...widget.components,
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
          child: Column(
            children: widget.childNodeWidgets,
          ),
        ),
      ],
    );
  }
}
