import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all products
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('admin_products').get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Add the document ID to the data
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  // Fetch products by category
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

  // Fetch flash sale products (you can define your own criteria for flash sale)
  Future<List<Map<String, dynamic>>> getFlashSaleProducts() async {
    try {
      // You might want to add a field like 'isFlashSale' to your products
      // or use a separate collection for flash sales
      // For now, let's just get the most recent products (limited to 5)
      QuerySnapshot querySnapshot = await _firestore
          .collection('admin_products')
          .orderBy('addedByAdmin', descending: true)
          .limit(5)
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
