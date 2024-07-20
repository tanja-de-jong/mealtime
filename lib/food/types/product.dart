class ProductCategory implements Comparable<ProductCategory> {
  final String? id;
  final String name;

  ProductCategory({this.id, required this.name});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  static ProductCategory fromJson(String? id, Map<String, dynamic> object) {
    return ProductCategory(
      id: id,
      name: object['name'],
    );
  }

  @override
  int compareTo(ProductCategory other) {
    return name.compareTo(other.name);
  }
}
