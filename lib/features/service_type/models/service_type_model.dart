class ServiceTypeModel {
  final int id;
  final String setypename;

  const ServiceTypeModel({
    required this.id,
    required this.setypename,
  });

  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) {
    return ServiceTypeModel(
      id: json['id'] as int? ?? 0,
      setypename: json['setypename']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toPayload() => {'setypename': setypename};

  ServiceTypeModel copyWith({int? id, String? setypename}) {
    return ServiceTypeModel(
      id: id ?? this.id,
      setypename: setypename ?? this.setypename,
    );
  }
}
