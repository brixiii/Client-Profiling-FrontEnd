import 'reseller_product.dart';

class Reseller {
  final int id;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String? notes;
  final List<ResellerProduct> products;

  const Reseller({
    required this.id,
    required this.companyName,
    required this.email,
    required this.phone,
    required this.address,
    this.notes,
    this.products = const [],
  });

  factory Reseller.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['reseller_products'];
    final products = rawProducts is List
        ? rawProducts
            .whereType<Map>()
            .map((e) => ResellerProduct.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <ResellerProduct>[];

    return Reseller(
      id: _asInt(json['id']),
      companyName: _asString(json['company_name']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      notes: json['notes']?.toString(),
      products: products,
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _asString(dynamic v) => v?.toString() ?? '';
}
