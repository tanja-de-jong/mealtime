class Product {
  final String? id;
  final String name;

  Product({this.id, required this.name});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  static Product fromJson(String? id, Map<String, dynamic> object) {
    return Product(
      id: id,
      name: object['name'],
    );
  }
}
