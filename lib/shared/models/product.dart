class Product {
  final int id;
  final String modelName;
  final String unitsofmeasurement;
  final String contractDate;
  final String deliveryDate;
  final String installmentDate;
  final String notes;
  final int clientId;
  final String modelCode;
  final String applianceType;
  final int employeeId;

  const Product({
    required this.id,
    required this.modelName,
    required this.unitsofmeasurement,
    required this.contractDate,
    required this.deliveryDate,
    required this.installmentDate,
    required this.notes,
    required this.clientId,
    required this.modelCode,
    required this.applianceType,
    required this.employeeId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      modelName: _asString(json['model_name']),
      unitsofmeasurement: _asString(json['unitsofmeasurement']),
      contractDate: _asString(json['contract_date']),
      deliveryDate: _asString(json['delivery_date']),
      installmentDate: _asString(json['installment_date']),
      notes: _asString(json['notes']),
      clientId: _asInt(json['client_id']),
      modelCode: _asString(json['model_code']),
      applianceType: _asString(json['appliance_type']),
      employeeId: _asInt(json['employee_id']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'model_name': modelName,
      'unitsofmeasurement': unitsofmeasurement,
      'contract_date': contractDate,
      'delivery_date': deliveryDate.isEmpty ? null : deliveryDate,
      'installment_date': installmentDate.isEmpty ? null : installmentDate,
      'notes': notes.isEmpty ? null : notes,
      'client_id': clientId,
      'model_code': modelCode,
      'appliance_type': applianceType,
      'employee_id': employeeId,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }
}
