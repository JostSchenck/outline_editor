import 'package:example_editor/src/outline_editor/mutable_document_depth_metadata.dart';
import 'package:example_editor/src/outline_editor/mutable_document_heading_metadata.dart';
import 'package:flutter/material.dart';

class OutlineExampleNavigationDrawer extends StatelessWidget {
  const OutlineExampleNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text('Example configurations'),
        ),
        ListTile(
          title: const Text('by depth metadata'),
          onTap: () {
            Navigator.popAndPushNamed(
                context, MutableDocumentDepthMetadataView.routeName);
          },
        ),
        ListTile(
          title: const Text('by heading blockType'),
          onTap: () {
            Navigator.popAndPushNamed(
                context, MutableDocumentHeadingMetadataView.routeName);
          },
        ),
      ],
    );
  }
}
