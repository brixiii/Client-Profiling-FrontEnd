class AvailedService {
  final int id;
  final int? eventId;
  final String notes;
  final String serviceDate;
  final String image;
  final String serialNumberId;
  final String controlNumber;
  final String serviceTypeId;
  final int? employeeId;
  final int clientId;
  final int? shopId;

  const AvailedService({
    required this.id,
    required this.eventId,
    required this.notes,
    required this.serviceDate,
    required this.image,
    required this.serialNumberId,
    required this.controlNumber,
    required this.serviceTypeId,
    required this.employeeId,
    required this.clientId,
    required this.shopId,
  });

  factory AvailedService.fromJson(Map<String, dynamic> json) {
    return AvailedService(
      id: _asInt(json['id']),
      eventId: _asNullableInt(json['event_id']),
      notes: _asString(json['notes']),
      serviceDate: _asString(json['service_date']),
      image: _asString(json['image']),
      serialNumberId: _asString(json['serial_number_id']),
      controlNumber: _asString(json['control_number']),
      serviceTypeId: _asString(json['service_type_id']),
      employeeId: _asNullableInt(json['employee_id']),
      clientId: _asInt(json['client_id']),
      shopId: _asNullableInt(json['shop_id']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'event_id': eventId,
      'notes': notes.isEmpty ? null : notes,
      'service_date': serviceDate,
      'image': image.isEmpty ? null : image,
      'serial_number_id': serialNumberId.isEmpty ? null : serialNumberId,
      'control_number': controlNumber.isEmpty ? null : controlNumber,
      'service_type_id': serviceTypeId,
      'employee_id': employeeId,
      'client_id': clientId,
      'shop_id': shopId,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _asString(dynamic value) {
    return value?.toString() ?? '';
  }
}
