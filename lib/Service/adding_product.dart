import 'dart:convert'; // For base64 encoding
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddingProduct {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to add product to Firestore
  // Future<String> addProduct({
  //   required String title,
  //   required String description,
  //   required String size,
  //   required List<String> color,
  //   required String category,
  //   required double price,
  //   required List<XFile> image, // Pass image as XFile
  // }) async {
  //   String res = "Some error occurred";

  //   try {
  //     // Convert the image to Base64 string
  //     String base64Image = await _convertImageToBase64(XFile as XFile);

  //     // Adding product data to Firestore
  //     await _firestore.collection('admin_products').add({
  //       'title': title,
  //       'description': description,
  //       'sizes': size,
  //       'colors': color,
  //       'category': category,
  //       'price': price,
  //       'imageURL': base64Image, // Storing the Base64 image string in Firestore
  //       'addedByAdmin': Timestamp.now(), // Timestamp of product creation
  //     });

  //     res = "Product added successfully!";
  //   } catch (e) {
  //     res = "Error adding product: $e";
  //   }

  //   return res;
  // }

  Future<String> addProduct({
    required String title,
    required String description,
    required String size,
    required List<String> color,
    required String category,
    required double price,
    required List<XFile> images, // Pass images as List<XFile>
  }) async {
    String res = "Some error occurred";

    try {
      // Convert each image to Base64 string
      List<String> base64Images = [];
      for (var image in images) {
        String base64Image = await _convertImageToBase64(image);
        base64Images.add(base64Image);
      }

      // Adding product data to Firestore
      await _firestore.collection('admin_products').add({
        'title': title,
        'description': description,
        'sizes': size,
        'colors': color,
        'category': category,
        'price': price,
        'imageURLs':
            base64Images, // Storing the Base64 image strings in Firestore
        'addedByAdmin': Timestamp.now(), // Timestamp of product creation
      });

      res = "Product added successfully!";
    } catch (e) {
      res = "Error adding product: $e";
    }

    return res;
  }

  // Helper method to convert image to Base64
  Future<String> _convertImageToBase64(XFile image) async {
    try {
      // Reading the image as bytes
      final bytes = await image.readAsBytes();
      // Converting bytes to Base64 string
      return base64Encode(bytes);
    } catch (e) {
      throw Exception("Error converting image to Base64: $e");
    }
  }
}
