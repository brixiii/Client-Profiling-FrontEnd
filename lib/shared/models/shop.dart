class Shop {
  final int id;
  final String shopname;
  final String saddress;
  final String svibernum;
  final String semailaddress;
  final String scontactperson;
  final String scontactnum;
  final String notes;
  final String shopTypeId;
  final int clientId;
  final String locationLink;
  final String pinLocation;

  const Shop({
    required this.id,
    required this.shopname,
    required this.saddress,
    required this.svibernum,
    required this.semailaddress,
    required this.scontactperson,
    required this.scontactnum,
    required this.notes,
    required this.shopTypeId,
    required this.clientId,
    required this.locationLink,
    required this.pinLocation,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: _asInt(json['id']),
      shopname: _asString(json['shopname']),
      saddress: _asString(json['saddress']),
      svibernum: _asString(json['svibernum']),
      semailaddress: _asString(json['semailaddress']),
      scontactperson: _asString(json['scontactperson']),
      scontactnum: _asString(json['scontactnum']),
      notes: _asString(json['notes']),
      shopTypeId: _asString(json['shop_type_id']),
      clientId: _asInt(json['client_id']),
      locationLink: _asString(json['location_link']),
      pinLocation: _asString(json['pin_location']),
    );
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
