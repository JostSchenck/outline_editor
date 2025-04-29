import 'package:collection/collection.dart';
import 'package:outline_editor/outline_editor.dart';
import 'package:outline_editor/src/infrastructure/uuid.dart';

class BasicOutlineTreenode extends OutlineTreenode<BasicOutlineTreenode> {
  BasicOutlineTreenode({
    required super.id,
    required super.titleNode,
    super.contentNodes,
    super.children,
    super.isCollapsed,
    super.hasContentHidden,
    super.metadata,
  });

  @override
  BasicOutlineTreenode copyWith({
    String? id,
    TitleNode? titleNode,
    List<DocumentNode>? contentNodes,
    List<BasicOutlineTreenode>? children,
    bool? isCollapsed,
    bool? hasContentHidden,
    Map<String, dynamic>? metadata,
  }) {
    return BasicOutlineTreenode(
      id: id ?? this.id,
      titleNode: titleNode ?? this.titleNode.copy() as TitleNode,
      contentNodes: contentNodes ?? [...this.contentNodes],
      children: children ?? this.children.map((c) => c.copyWith()).toList(),
      isCollapsed: isCollapsed ?? this.isCollapsed,
      hasContentHidden: hasContentHidden ?? this.hasContentHidden,
      metadata: metadata != null
          ? UnmodifiableMapView(metadata)
          : UnmodifiableMapView(Map<String, dynamic>.from(this.metadata)),
    );
  }

  @override
  BasicOutlineTreenode copyWithDeep({
    String? id,
    TitleNode? titleNode,
    List<DocumentNode>? contentNodes,
    List<BasicOutlineTreenode>? children,
    bool? isCollapsed,
    bool? hasContentHidden,
    Map<String, dynamic>? metadata,
  }) {
    return BasicOutlineTreenode(
      id: id ?? this.id,
      titleNode: titleNode ?? this.titleNode.copy() as TitleNode,
      contentNodes: contentNodes ??
          this.contentNodes.map((n) => (n as TextNode).copy()).toList(),
      children: children ?? this.children.map((t) => t.copyWithDeep()).toList(),
      isCollapsed: isCollapsed ?? this.isCollapsed,
      hasContentHidden: hasContentHidden ?? this.hasContentHidden,
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        other is OutlineTreenode &&
        other.id == id &&
        other.titleNode == titleNode &&
        other.isCollapsed == isCollapsed &&
        other.hasContentHidden == hasContentHidden &&
        const DeepCollectionEquality()
            .equals(other.contentNodes, contentNodes) &&
        const DeepCollectionEquality().equals(other.children, children) &&
        const DeepCollectionEquality().equals(other.metadata, metadata);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      titleNode.hashCode ^
      contentNodes.hashCode ^
      children.hashCode ^
      isCollapsed.hashCode ^
      hasContentHidden.hashCode ^
      metadata.hashCode;
}

class BasicOutlineEditableDocument
    extends OutlineEditableDocument<BasicOutlineTreenode> {
  BasicOutlineEditableDocument({
    super.treenodeBuilder = basicOutlineTreenodeBuilder,
  });
}

BasicOutlineTreenode basicOutlineTreenodeBuilder({
  String? id,
  TitleNode? titleNode,
  List<DocumentNode>? contentNodes,
}) =>
    BasicOutlineTreenode(
      id: id ?? uuid.v4(),
      contentNodes: contentNodes ?? [],
      titleNode: titleNode ??
          TitleNode(
            id: uuid.v4(),
            text: AttributedText(''),
          ),
    );
