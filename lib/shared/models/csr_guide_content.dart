class CsrGuideContent {
  final int id;
  final int sectionId;
  final String content;

  const CsrGuideContent({
    required this.id,
    required this.sectionId,
    required this.content,
  });

  factory CsrGuideContent.fromJson(Map<String, dynamic> json) {
    return CsrGuideContent(
      id: json['id'] as int? ?? 0,
      sectionId: json['section_id'] as int? ?? 0,
      content: json['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section_id': sectionId,
        'content': content,
      };
}
