import 'csr_guide_content.dart';

class CsrGuideSection {
  final int id;
  final String title;
  final String slug;
  final int order;
  final int? parentId;
  final List<CsrGuideSection> children;
  final List<CsrGuideContent> content;

  const CsrGuideSection({
    required this.id,
    required this.title,
    required this.slug,
    required this.order,
    this.parentId,
    required this.children,
    required this.content,
  });

  factory CsrGuideSection.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final rawContent = json['content'];
    return CsrGuideSection(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      order: json['order'] as int? ?? 0,
      parentId: json['parent_id'] as int?,
      children: (rawChildren is List ? rawChildren : <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CsrGuideSection.fromJson)
          .toList(),
      content: (rawContent is List ? rawContent : <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CsrGuideContent.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'order': order,
        'parent_id': parentId,
        'children': children.map((c) => c.toJson()).toList(),
        'content': content.map((c) => c.toJson()).toList(),
      };
}
