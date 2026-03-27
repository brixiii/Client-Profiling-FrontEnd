class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final List<dynamic> links;

  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.links,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final rawData = json['data'];
    final rows = rawData is List ? rawData : const [];

    // Backend wraps pagination fields in a "meta" key.
    // Fall back to the root object for endpoints that return them inline.
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : json;

    return PaginatedResponse<T>(
      data: rows
          .whereType<Map>()
          .map((e) => itemParser(Map<String, dynamic>.from(e)))
          .toList(),
      currentPage: _asInt(meta['current_page']),
      perPage: _asInt(meta['per_page']),
      total: _asInt(meta['total']),
      lastPage: _asInt(meta['last_page']),
      links:
          json['links'] is List ? List<dynamic>.from(json['links']) : const [],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
