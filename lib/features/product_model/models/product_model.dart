/// Domain model mapped to backend: id, modelname, model_code, appliance_type, status.
class ProductModel {
  final int id;
  final String modelname;
  final String modelCode;
  final String applianceType;
  final String status;

  const ProductModel({
    required this.id,
    required this.modelname,
    required this.modelCode,
    required this.applianceType,
    required this.status,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      modelname: json['modelname']?.toString() ?? '',
      modelCode: json['model_code']?.toString() ?? '',
      applianceType: json['appliance_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toPayload() => {
        'modelname': modelname,
        'model_code': modelCode,
        'appliance_type': applianceType,
        'status': status,
      };

  ProductModel copyWith({
    int? id,
    String? modelname,
    String? modelCode,
    String? applianceType,
    String? status,
  }) {
    return ProductModel(
      id: id ?? this.id,
      modelname: modelname ?? this.modelname,
      modelCode: modelCode ?? this.modelCode,
      applianceType: applianceType ?? this.applianceType,
      status: status ?? this.status,
    );
  }
}
