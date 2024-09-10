import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

var defaultStructuredEditorStylesheet = defaultStylesheet.copyWith(
  documentPadding: EdgeInsets.zero,
  rules: [
    StyleRule(
      BlockSelector.all,
          (doc, docNode) {
        return {
          Styles.maxWidth: 640.0,
          Styles.padding: const CascadingPadding.symmetric(vertical:8, horizontal: 0),
          Styles.textStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            height: 1.4,
          ),
          // Styles.textAlign: TextAlignVertical.top,
        };
      },
    ),
  ],
);
