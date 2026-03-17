class SparePartModel {
  final String id;
  final String name;
  final String partNumber;
  final int stock;
  final String unit;

  // Fields shown in the image form screens
  final int quantity;
  final String date;
  final String notes;

  const SparePartModel({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.stock,
    required this.unit,
    this.quantity = 0,
    this.date = '',
    this.notes = '',
  });

  SparePartModel copyWith({
    String? id,
    String? name,
    String? partNumber,
    int? stock,
    String? unit,
    int? quantity,
    String? date,
    String? notes,
  }) {
    return SparePartModel(
      id: id ?? this.id,
      name: name ?? this.name,
      partNumber: partNumber ?? this.partNumber,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
