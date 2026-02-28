// lib/models/product.dart

class Product {
  final int? id;
  final String code;
  final String designation;
  final String barcode;
  final double price;
  int quantity;

  Product({
    this.id,
    required this.code,
    required this.designation,
    required this.barcode,
    required this.price,
    this.quantity = 0,
  });

  // Conversion pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'designation': designation,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
    };
  }

  // Création depuis SQLite
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      code: map['code'] ?? '',
      designation: map['designation'] ?? '',
      barcode: map['barcode'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }

  // Pour affichage
  @override
  String toString() {
    return 'Product(code: $code, designation: $designation, barcode: $barcode, quantity: $quantity)';
  }
}