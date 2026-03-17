class SerialNumberModel {
  final String id;
  final String clientName;
  final String clientType;
  final String dateCreated;
  final String productModel;
  final List<String> serialCodes;

  const SerialNumberModel({
    required this.id,
    required this.clientName,
    required this.clientType,
    required this.dateCreated,
    required this.productModel,
    this.serialCodes = const [],
  });

  SerialNumberModel copyWith({
    String? id,
    String? clientName,
    String? clientType,
    String? dateCreated,
    String? productModel,
    List<String>? serialCodes,
  }) {
    return SerialNumberModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientType: clientType ?? this.clientType,
      dateCreated: dateCreated ?? this.dateCreated,
      productModel: productModel ?? this.productModel,
      serialCodes: serialCodes ?? this.serialCodes,
    );
  }
}
