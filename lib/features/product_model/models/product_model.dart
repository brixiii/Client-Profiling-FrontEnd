class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;

  // Fields shown in the image form screens
  final String modelCode;
  final String washerCode;
  final String dryerCode;
  final String stylerCode;
  final String paymentSystem;

  const ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    this.modelCode = '',
    this.washerCode = '',
    this.dryerCode = '',
    this.stylerCode = '',
    this.paymentSystem = '',
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? description,
    String? modelCode,
    String? washerCode,
    String? dryerCode,
    String? stylerCode,
    String? paymentSystem,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      description: description ?? this.description,
      modelCode: modelCode ?? this.modelCode,
      washerCode: washerCode ?? this.washerCode,
      dryerCode: dryerCode ?? this.dryerCode,
      stylerCode: stylerCode ?? this.stylerCode,
      paymentSystem: paymentSystem ?? this.paymentSystem,
    );
  }
}
