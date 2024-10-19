import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

var defaultOutlineEditorStylesheet = defaultStylesheet.copyWith(
  documentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
    StyleRule(const BlockSelector('title'), (doc, docNode) {
      return {
        Styles.maxWidth: 640.0,
        Styles.padding: const CascadingPadding.only(top: 16, bottom: 8),
        Styles.textStyle: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black26,
          fontSize: 15,
          height: 1.4,
        ),
      };
    }),
  ],
);
