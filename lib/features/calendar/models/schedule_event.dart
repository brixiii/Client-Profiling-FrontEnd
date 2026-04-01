import 'package:flutter/material.dart';

enum ScheduleType { pending, tentative, final_, resolved, name }

enum NameType { default_, asterisk }

class ScheduleEvent {
  final int id;
  final int shopId;
  final int serviceTypeId;
  final String name;
  final ScheduleType type;
  final String contactNo;
  final NameType nameType;
  final String shop;
  final String addressLocation;
  final String pinLocation;
  final String locationLink;
  final String serviceType;
  final String vehicles;
  final String tollAmount;
  final String gasAmount;
  final List<String> technicians;
  final String notes;
  final String createdBy;

  ScheduleEvent({
    this.id = 0,
    this.shopId = 0,
    this.serviceTypeId = 0,
    required this.name,
    required this.type,
    this.contactNo = '',
    this.nameType = NameType.default_,
    this.shop = '',
    this.addressLocation = '',
    this.pinLocation = '',
    this.locationLink = '',
    this.serviceType = '',
    this.vehicles = '',
    this.tollAmount = '0.00',
    this.gasAmount = '0.00',
    List<String>? technicians,
    this.notes = 'N/A',
    this.createdBy = '',
  }) : technicians = technicians ?? ['N/A', 'N/A', 'N/A', 'N/A', 'N/A'];

  /// Shows "* Name" when marked as Asterisk, plain name otherwise.
  String get displayName =>
      nameType == NameType.asterisk ? '* $name' : name;

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    final rawTechs = (json['technicians'] as List? ?? []);
    final techs = rawTechs
        .map<String>((t) => _asString((t as Map?)?['efullname']))
        .where((n) => n.isNotEmpty)
        .toList();
    while (techs.length < 5) techs.add('N/A');

    return ScheduleEvent(
      id: _asInt(json['id']),
      shopId: _asInt(json['shop_id']),
      serviceTypeId: _asInt(json['service_type_id']),
      name: _asString(json['client_name']),
      type: _typeFromString(_asString(json['status'])),
      contactNo: _asString(json['phone']),
      nameType:
          json['event_mark'] == null ? NameType.default_ : NameType.asterisk,
      shop: '',
      addressLocation: _asString(json['location']),
      pinLocation: _asString(json['pin_location']),
      locationLink: _asString(json['location_link']),
      serviceType: json['service_type'] is Map
          ? _asString((json['service_type'] as Map)['setypename'])
          : _asString(json['services']),
      vehicles: _asString(json['vehicles']),
      tollAmount: _asString(json['toll_amount']).isEmpty
          ? '0.00'
          : _asString(json['toll_amount']),
      gasAmount: _asString(json['gas_amount']).isEmpty
          ? '0.00'
          : _asString(json['gas_amount']),
      technicians: techs,
      notes:
          _asString(json['notes']).isEmpty ? 'N/A' : _asString(json['notes']),
      createdBy: _asString(json['created_by']),
    );
  }

  ScheduleEvent copyWith({
    int? id,
    int? shopId,
    int? serviceTypeId,
    String? name,
    ScheduleType? type,
    String? contactNo,
    NameType? nameType,
    String? shop,
    String? addressLocation,
    String? pinLocation,
    String? locationLink,
    String? serviceType,
    String? vehicles,
    String? tollAmount,
    String? gasAmount,
    List<String>? technicians,
    String? notes,
    String? createdBy,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      name: name ?? this.name,
      type: type ?? this.type,
      contactNo: contactNo ?? this.contactNo,
      nameType: nameType ?? this.nameType,
      shop: shop ?? this.shop,
      addressLocation: addressLocation ?? this.addressLocation,
      pinLocation: pinLocation ?? this.pinLocation,
      locationLink: locationLink ?? this.locationLink,
      serviceType: serviceType ?? this.serviceType,
      vehicles: vehicles ?? this.vehicles,
      tollAmount: tollAmount ?? this.tollAmount,
      gasAmount: gasAmount ?? this.gasAmount,
      technicians: technicians ?? List.from(this.technicians),
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ── Type helpers ─────────────────────────────────────────────────────────

  static ScheduleType _typeFromString(String status) {
    switch (status.toLowerCase()) {
      case 'tentative':
        return ScheduleType.tentative;
      case 'final':
        return ScheduleType.final_;
      case 'resolved':
        return ScheduleType.resolved;
      default:
        return ScheduleType.pending;
    }
  }

  static String typeToString(ScheduleType type) {
    switch (type) {
      case ScheduleType.pending:
        return 'pending';
      case ScheduleType.tentative:
        return 'tentative';
      case ScheduleType.final_:
        return 'final';
      case ScheduleType.resolved:
        return 'resolved';
      case ScheduleType.name:
        return 'pending';
    }
  }

  static Color colorForType(ScheduleType type) {
    switch (type) {
      case ScheduleType.pending:
        return const Color(0xFF5B9BD5);
      case ScheduleType.tentative:
        return const Color(0xFFFFA500);
      case ScheduleType.final_:
        return const Color(0xFFE74C3C);
      case ScheduleType.resolved:
        return const Color(0xFF27AE60);
      case ScheduleType.name:
        return const Color(0xFF95A5A6);
    }
  }

  Color get color => colorForType(type);

  // ── Raw helpers ───────────────────────────────────────────────────────────

  static int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse((v ?? '').toString()) ?? 0;
  }

  static String _asString(dynamic v) => (v ?? '').toString().trim();
}