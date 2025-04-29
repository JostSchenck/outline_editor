import 'package:outline_editor/outline_editor.dart';

OutlineEditableDocument<BasicOutlineTreenode> buildTestDocumentFromString(
    String input) {
  final lines = input.trim().split('\n');
  final stack = <({int indent, BasicOutlineTreenode treenode})>[];

  BasicOutlineTreenode? root;

  for (final rawLine in lines) {
    final line = rawLine.replaceAll('\t', '  ');
    final indent = line.indexOf(RegExp(r'\S')) ~/ 2;

    if (line.trimLeft().startsWith('>')) {
      final contentLine = line.trimLeft().substring(1);
      final sepIndex = contentLine.indexOf(':');
      if (sepIndex == -1) throw Exception('Invalid content line: $line');
      final id = contentLine.substring(0, sepIndex).trim();
      final text = contentLine.substring(sepIndex + 1);

      final last = stack.removeLast();
      final updatedContent = [
        ...last.treenode.contentNodes,
        ParagraphNode(id: id, text: AttributedText(text))
      ];
      var updated = last.treenode.copyWith(contentNodes: updatedContent);
      stack.add((indent: last.indent, treenode: updated));

      if (stack.length == 1) {
        root = updated;
      } else {
        for (int i = stack.length - 2; i >= 0; i--) {
          final parent = stack[i];
          final replaced =
              parent.treenode.replaceTreenodeById(updated.id, (_) => updated);
          stack[i] = (indent: parent.indent, treenode: replaced);
          updated = replaced;
        }
        root = stack.first.treenode;
      }
      continue;
    }

    final sep = line.indexOf(':');
    if (sep == -1) throw Exception('Missing ":" in: $line');
    final id = line.substring(0, sep).trim();
    final text = line.substring(sep + 1).trim();
    final titleNode = TitleNode(id: id, text: AttributedText(text));
    final newTreenode = BasicOutlineTreenode(id: id, titleNode: titleNode);

    while (stack.isNotEmpty && stack.last.indent >= indent) {
      stack.removeLast();
    }

    if (stack.isEmpty) {
      root = newTreenode;
      stack.add((indent: indent, treenode: newTreenode));
      continue;
    }

    final parent = stack.removeLast();
    var updatedParent = parent.treenode.copyInsertChild(
        child: newTreenode, atIndex: parent.treenode.children.length);
    stack.add((indent: parent.indent, treenode: updatedParent));
    stack.add((indent: indent, treenode: newTreenode));

    if (updatedParent.id == root!.id) {
      root = updatedParent;
    } else {
      for (int i = stack.length - 3; i >= 0; i--) {
        final grandParent = stack[i];
        final replaced = grandParent.treenode
            .replaceTreenodeById(updatedParent.id, (_) => updatedParent);
        stack[i] = (indent: grandParent.indent, treenode: replaced);
        updatedParent = replaced;
      }
      root = stack.first.treenode;
    }
  }

  return OutlineEditableDocument<BasicOutlineTreenode>(
    treenodeBuilder: basicOutlineTreenodeBuilder,
    logicalRoot: root!,
  );
}

extension OutlineEditableDocumentPrettyPrinter
    on OutlineEditableDocument<BasicOutlineTreenode> {
  String toPrettyTestString() {
    final buffer = StringBuffer();

    void writeTreenode(BasicOutlineTreenode node, int indent) {
      final indentStr = '  ' * indent;
      buffer
          .writeln('$indentStr${node.id}:${node.titleNode.text.toPlainText()}');
      for (final content in node.contentNodes) {
        if (content is ParagraphNode) {
          buffer.writeln(
              '$indentStr  > ${content.id}:${content.text.toPlainText()}');
        }
      }
      for (final child in node.children) {
        writeTreenode(child, indent + 1);
      }
    }

    writeTreenode(root, 0);
    return buffer.toString().trimRight();
  }
}
