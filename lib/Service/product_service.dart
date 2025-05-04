import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetching all products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('admin_products').get();

      final products = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Adding the document ID to the data
        data['id'] = doc.id;
        return data;
      }).toList();

      developer.log("Fetched ${products.length} products");
      _logImageInfo(products);

      return products;
    } catch (e) {
      developer.log("Error fetching products: $e");
      return [];
    }
  }

  // Fetching products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
      String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('admin_products')
          .where('category', isEqualTo: category)
          .get();

      final products = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      developer
          .log("Fetched ${products.length} products for category: $category");
      _logImageInfo(products);

      return products;
    } catch (e) {
      developer.log("Error fetching products by category: $e");
      return [];
    }
  }

  // Fetching flash sale products (you can define your own criteria for flash sale)
  Future<List<Map<String, dynamic>>> getFlashSaleProducts() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('admin_products')
          .orderBy('addedByAdmin', descending: true)
          .limit(10)
          .get();

      final products = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      developer.log("Fetched ${products.length} flash sale products");
      _logImageInfo(products);

      return products;
    } catch (e) {
      developer.log("Error fetching flash sale products: $e");
      return [];
    }
  }

  // Helper to log image information for debugging
  void _logImageInfo(List<Map<String, dynamic>> products) {
    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final title = product['title'] ?? 'Unknown';

      // Check for image fields
      final hasImageURLs = product.containsKey('imageURLs');
      final hasImages = product.containsKey('images');
      final hasImage = product.containsKey('image');
      final hasImageUrl = product.containsKey('imageUrl');
      final hasImageURL = product.containsKey('imageURL');
      final hasDownloadURL = product.containsKey('downloadURL');
      final hasBase64Image = product.containsKey('base64Image');

      developer
          .log("Product '$title' (${i + 1}/${products.length}) image fields: "
              "imageURLs: $hasImageURLs, "
              "images: $hasImages, "
              "image: $hasImage, "
              "imageUrl: $hasImageUrl, "
              "imageURL: $hasImageURL, "
              "downloadURL: $hasDownloadURL, "
              "base64Image: $hasBase64Image");
    }
  }
}
