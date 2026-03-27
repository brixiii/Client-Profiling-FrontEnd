import 'package:flutter/foundation.dart' show debugPrint;

class User {
  final int id;
  final String name;
  final String email;
  // 'phone' maps to both 'phone' and 'phonenum' fields depending on endpoint.
  final String phone;
  final String username;
  final String firstname;
  final String middlename;
  final String surname;
  final String address;
  final String role;
  final String? profilePhotoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.username = '',
    this.firstname = '',
    this.middlename = '',
    this.surname = '',
    this.address = '',
    this.role = '',
    this.profilePhotoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawPhotoValue = json['profile_photo_url'];
    debugPrint('[User.fromJson] raw profile_photo_url: $rawPhotoValue (type: ${rawPhotoValue?.runtimeType})');
    final photoUrl = _asString(rawPhotoValue);
    debugPrint('[User.fromJson] parsed photoUrl: "$photoUrl", isEmpty: ${photoUrl.isEmpty}');
    final firstname = _asString(json['firstname']);
    final middlename = _asString(json['middlename']);
    final surname = _asString(json['surname']);
    final fullName = _asString(json['name']).isNotEmpty
        ? _asString(json['name'])
        : [firstname, middlename, surname]
            .where((s) => s.isNotEmpty)
            .join(' ');
    return User(
      id: _asInt(json['id']),
      name: fullName,
      email: _asString(json['email']),
      // /profile returns 'phonenum'; other endpoints return 'phone'.
      phone: _asString(json['phonenum'] ?? json['phone']),
      username: _asString(json['username']),
      firstname: firstname,
      middlename: middlename,
      surname: surname,
      address: _asString(json['address']),
      role: _asString(json['role']),
      profilePhotoUrl: photoUrl.isEmpty ? null : photoUrl,
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
