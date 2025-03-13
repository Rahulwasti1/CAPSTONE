import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetching all products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('admin_products').get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Adding the document ID to the data
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching products: $e");
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

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching products by category: $e");
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

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching flash sale products: $e");
      return [];
    }
  }
}
