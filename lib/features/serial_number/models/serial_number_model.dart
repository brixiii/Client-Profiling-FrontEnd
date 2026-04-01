class SerialNumberModel {
  final int id;
  final String serialnumber;
  final int clientId;
  final int? shopProductId;
  final String supplierType;
  final String createdAt;
  final String clientFirstname;
  final String clientSurname;

  const SerialNumberModel({
    required this.id,
    required this.serialnumber,
    required this.clientId,
    this.shopProductId,
    this.supplierType = '',
    required this.createdAt,
    this.clientFirstname = '',
    this.clientSurname = '',
  });

  String get clientName =>
      '${clientFirstname.trim()} ${clientSurname.trim()}'.trim();

  factory SerialNumberModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return SerialNumberModel(
      id: (json['id'] as num).toInt(),
      serialnumber: json['serialnumber'] as String? ?? '',
      clientId: (json['client_id'] as num).toInt(),
      shopProductId: json['shop_product_id'] != null
          ? (json['shop_product_id'] as num).toInt()
          : null,
      supplierType: json['supplier_type'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      clientFirstname: client?['cfirstname'] as String? ?? '',
      clientSurname: client?['csurname'] as String? ?? '',
    );
  }

  SerialNumberModel copyWith({
    int? id,
    String? serialnumber,
    int? clientId,
    int? shopProductId,
    String? supplierType,
    String? createdAt,
    String? clientFirstname,
    String? clientSurname,
  }) {
    return SerialNumberModel(
      id: id ?? this.id,
      serialnumber: serialnumber ?? this.serialnumber,
      clientId: clientId ?? this.clientId,
      shopProductId: shopProductId ?? this.shopProductId,
      supplierType: supplierType ?? this.supplierType,
      createdAt: createdAt ?? this.createdAt,
      clientFirstname: clientFirstname ?? this.clientFirstname,
      clientSurname: clientSurname ?? this.clientSurname,
    );
  }
}
