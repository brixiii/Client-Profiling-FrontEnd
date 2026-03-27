class Employee {
  final int id;
  final String name;
  final String email;
  final String role;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    this.role = '',
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _asInt(json['id']),
      name: _asString(json['efullname'] ?? json['name']),
      email: _asString(json['email']),
      // employee_type_id is an integer foreign key; stringify for display.
      role: _asString(json['employee_type_id'] ?? json['role'] ?? ''),
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
