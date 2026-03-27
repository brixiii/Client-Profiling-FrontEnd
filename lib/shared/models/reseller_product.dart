class ResellerProduct {
  final int id;
  final int resellerId;
  final String modelName;
  final String modelCode;
  final String applianceType;
  final String unitsOfMeasurement;
  final int quantity;
  final String poNumber;
  final String drNumber;
  final String deliveryDate;
  final String deliveryAddress;
  final String customerRepresentative;
  final String? notes;
  /// Populated from the first embedded serial's supplier_type.
  final String supplierType;
  final List<String> serials;
  

  const ResellerProduct({
    required this.id,
    required this.resellerId,
    required this.modelName,
    required this.modelCode,
    required this.applianceType,
    required this.unitsOfMeasurement,
    required this.quantity,
    required this.poNumber,
    required this.drNumber,
    required this.deliveryDate,
    required this.deliveryAddress,
    required this.customerRepresentative,
    this.notes,
    this.supplierType = '',
    this.serials = const [],
  });

  factory ResellerProduct.fromJson(Map<String, dynamic> json) {
    final rawSerials = json['reseller_product_serials'];
    var supplierType = '';
    final serials = <String>[];
    if (rawSerials is List) {
      for (final s in rawSerials.whereType<Map>()) {
        final sn = s['serialnumber']?.toString() ?? '';
        if (sn.isNotEmpty) serials.add(sn);
        if (supplierType.isEmpty) {
          supplierType = s['supplier_type']?.toString() ?? '';
        }
      }
    }

    return ResellerProduct(
      id: _asInt(json['id']),
      resellerId: _asInt(json['reseller_id']),
      modelName: _asString(json['model_name']),
      modelCode: _asString(json['model_code']),
      applianceType: _asString(json['appliance_type']),
      unitsOfMeasurement: _asString(json['unitsofmeasurement']),
      quantity: _asInt(json['quantity']),
      poNumber: _asString(json['po_number']),
      drNumber: _asString(json['dr_number']),
      deliveryDate: _asString(json['delivery_date']),
      deliveryAddress: _asString(json['delivery_address']),
      customerRepresentative: _asString(json['customer_representative']),
      notes: json['notes']?.toString(),
      supplierType: supplierType,
      serials: serials,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _asString(dynamic v) => v?.toString() ?? '';
}
