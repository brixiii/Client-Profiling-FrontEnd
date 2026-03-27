import 'product.dart';

class ShopProduct {
  final int id;
  final int shopId;
  final int productId;
  final int quantity;
  final int? clientId;
  final Product product;

  const ShopProduct({
    required this.id,
    required this.shopId,
    required this.productId,
    required this.quantity,
    required this.clientId,
    required this.product,
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final nestedProduct = json['product'];
    final productJson = nestedProduct is Map<String, dynamic>
        ? nestedProduct
        : Map<String, dynamic>.from(json);

    return ShopProduct(
      id: _asInt(json['id']),
      shopId: _asInt(json['shop_id']),
      productId: _asInt(json['product_id']),
      quantity: _asInt(json['quantity'], fallback: 1),
      clientId: _asNullableInt(json['client_id']),
      product: Product.fromJson(productJson),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
