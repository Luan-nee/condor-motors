import 'dart:convert';
import 'dart:math' show max;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class StorageService {
  static const String _productsKey = 'products';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<List<Product>> getProducts() async {
    final String? productsJson = _prefs.getString(_productsKey);
    if (productsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(productsJson);
    return decoded.map((item) => Product.fromJson(item)).toList();
  }

  Future<void> saveProducts(List<Product> products) async {
    final String encoded = jsonEncode(
      products.map((p) => p.toJson()).toList(),
    );
    await _prefs.setString(_productsKey, encoded);
  }

  Future<void> addProduct(Product product) async {
    final products = await getProducts();
    products.add(product);
    await saveProducts(products);
  }

  Future<void> updateProduct(Product product) async {
    final products = await getProducts();
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      await saveProducts(products);
    }
  }

  Future<void> deleteProduct(int productId) async {
    final products = await getProducts();
    products.removeWhere((p) => p.id == productId);
    await saveProducts(products);
  }

  // Obtener el último ID usado
  Future<int> getLastProductId() async {
    final products = await getProducts();
    if (products.isEmpty) return 0;
    return products.map((p) => p.id).reduce((a, b) => max(a, b));
  }
} 