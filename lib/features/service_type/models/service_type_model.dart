class ServiceTypeModel {
  final String id;
  final String name;
  final String description;
  final double price;

  const ServiceTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  ServiceTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
  }) {
    return ServiceTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }
}
