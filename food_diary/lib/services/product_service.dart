import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_product.dart';

class ProductService {
  Future<FoodProduct?> fetchProductByBarcode(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return FoodProduct.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}