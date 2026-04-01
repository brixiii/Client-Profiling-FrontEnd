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

  /// Parsed from `availed_service_serials` or `serials` relationship array.
  /// Each entry is a serial number string (e.g. "SN-001").
  final List<String> serialNumbersList;

  /// Parsed from `serial_spare_parts` nested under each `availed_service_serial`.
  /// Each entry: { 'name': String, 'quantity': int }
  final List<Map<String, dynamic>> sparePartsList;

  /// Parsed from `technicians` or `availed_service_employees` relationship array.
  final List<String> technicianNames;

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
    this.serialNumbersList = const [],
    this.sparePartsList = const [],
    this.technicianNames = const [],
  });

  factory AvailedService.fromJson(Map<String, dynamic> json) {
    // Parse serial numbers from the pivot relationship (list of serials).
    // Laravel may return as 'availed_service_serials' or 'serials'.
    final rawSerials = (json['availed_service_serials'] as List? ??
        json['serials'] as List? ??
        []);
    final serialNumbersList = <String>[];
    final sparePartsList = <Map<String, dynamic>>[];

    for (final entry in rawSerials) {
      if (entry is! Map) continue;
      final snMap = entry['serial_number'] as Map?;
      final snStr = snMap != null
          ? _asString(snMap['serialnumber'])
          : _asString(entry['serial_number_id']);
      if (snStr.isNotEmpty) serialNumbersList.add(snStr);

      // Spare parts nested under each serial (serial_spare_parts relation).
      final rawSpareParts = (entry['serial_spare_parts'] as List? ??
          entry['spare_parts'] as List? ??
          []);
      for (final sp in rawSpareParts) {
        if (sp is! Map) continue;
        final spMap = sp['spare_part'] as Map?;
        final name = spMap != null
            ? _asString(spMap['sparepartsname'])
            : _asString(sp['sparepartsname'] ?? sp['spare_part_id']);
        final qty = _asNullableInt(sp['quantity']) ?? 1;
        if (name.isNotEmpty) {
          sparePartsList.add({'name': name, 'quantity': qty});
        }
      }
    }

    // Parse technicians from 'technicians' (array of {efullname}) or
    // 'availed_service_employees' (array of {employee: {efullname}}).
    final rawTechs = (json['technicians'] as List? ??
        json['availed_service_employees'] as List? ??
        []);
    final technicianNames = <String>[];
    for (final t in rawTechs) {
      if (t is! Map) continue;
      final empMap = t['employee'] as Map?;
      final name = empMap != null
          ? _asString(empMap['efullname'])
          : _asString(t['efullname'] ?? t['name']);
      if (name.isNotEmpty) technicianNames.add(name);
    }

    return AvailedService(
      id: _asInt(json['id']),
      eventId: _asNullableInt(json['event_id']),
      notes: _asString(json['notes']),
      serviceDate: _asString(json['service_date']),
      image: _asString(json['image']),
      serialNumberId: _asString(json['serial_number_id']),
      controlNumber: _asString(
          json['control_number'] ?? json['service_order_report_no']),
      serviceTypeId: _asString(json['service_type_id']),
      employeeId: _asNullableInt(json['employee_id']),
      clientId: _asInt(json['client_id']),
      shopId: _asNullableInt(json['shop_id']),
      serialNumbersList: serialNumbersList,
      sparePartsList: sparePartsList,
      technicianNames: technicianNames,
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
