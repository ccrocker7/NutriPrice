class FoodProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String? calories;

  FoodProduct({
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.calories,
  });

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