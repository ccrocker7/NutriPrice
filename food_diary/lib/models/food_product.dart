class FoodProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String? calories;

  FoodProduct({
    required this.name, 
    required this.brand, 
    required this.imageUrl, 
    this.calories
  });

  // Convert a FoodProduct to a Map to store in Hive
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'calories': calories,
    };
  }

  // Create a FoodProduct from a Hive Map
  factory FoodProduct.fromMap(Map<dynamic, dynamic> map) {
    return FoodProduct(
      name: map['name'] ?? 'Unknown',
      brand: map['brand'] ?? 'Unknown',
      imageUrl: map['imageUrl'] ?? '',
      calories: map['calories'],
    );
  }

  factory FoodProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return FoodProduct(
      name: product['product_name'] ?? 'Unknown Product',
      brand: product['brands'] ?? 'Unknown Brand',
      imageUrl: product['image_front_url'] ?? '',
      calories: product['nutriments']?['energy-kcal_100g']?.toString(),
    );
  }
}