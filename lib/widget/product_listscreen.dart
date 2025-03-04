// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'product_card.dart'; // Import the ProductCard widget

// class ProductListScreen extends StatefulWidget {
//   @override
//   _ProductListScreenState createState() => _ProductListScreenState();
// }

// class _ProductListScreenState extends State<ProductListScreen> {
//   List<Map<String, dynamic>> productList = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchProducts(); // Fetch the products when the screen is loaded
//   }

//   Future<void> fetchProducts() async {
//     try {
//       QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('admin_products').get();

//       // Ensure that imageURLs and other fields exist in each product
//       List<Map<String, dynamic>> products = snapshot.docs.map((doc) {
//         return {
//           'title': doc['title'] ??
//               'Unknown Product', // Fallback to 'Unknown Product'
//           'price': doc['price'] ?? 0, // Fallback to 0 if no price
//           'description': doc['description'] ??
//               'No description available', // Fallback to default description
//           'imageURLs': doc['imageURLs'] != null
//               ? List<String>.from(doc['imageURLs'])
//               : [],
//           'colors':
//               doc['colors'] != null ? List<String>.from(doc['colors']) : [],
//         };
//       }).toList();

//       setState(() {
//         productList = products;
//       });
//     } catch (e) {
//       print('Error fetching products: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Products')),
//       body: productList.isEmpty
//           ? Center(
//               child:
//                   CircularProgressIndicator()) // Show loading if data is empty
//           : ListView.builder(
//               itemCount: productList.length,
//               itemBuilder: (context, index) {
//                 return ProductCard(
//                     product:
//                         productList[index]); // Pass each product to ProductCard
//               },
//             ),
//     );
//   }
// }
