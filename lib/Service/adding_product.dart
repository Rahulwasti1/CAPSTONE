import 'dart:convert'; // For base64 encoding
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

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

  // Resize and compress image to reduce size
  Future<Uint8List> _resizeAndCompressImage(Uint8List imageBytes) async {
    // Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    // Get image dimensions
    final int width = frameInfo.image.width;
    final int height = frameInfo.image.height;

    // Calculate new dimensions (aim for max 800px on longest side)
    int newWidth = width;
    int newHeight = height;

    if (width > height && width > 800) {
      newWidth = 800;
      newHeight = (height * 800 / width).round();
    } else if (height > 800) {
      newHeight = 800;
      newWidth = (width * 800 / height).round();
    }

    // Create a new picture with smaller dimensions
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw the image at the new size
    canvas.drawImageRect(
      frameInfo.image,
      Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble()),
      Rect.fromLTRB(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint(),
    );

    // Convert to image
    final ui.Image resizedImage =
        await pictureRecorder.endRecording().toImage(newWidth, newHeight);

    // Convert to bytes in PNG format (good balance of quality and size)
    final ByteData? byteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  Future<String> addProduct({
    required String title,
    required String description,
    required dynamic size, // Accept either String or List<String>
    required List<String> color,
    required String category,
    required String genderCategory,
    required double price,
    required List<XFile> images, // Pass images as List<XFile>
  }) async {
    String res = "Some error occurred";

    try {
      // Basic input validation
      if (title.isEmpty ||
          description.isEmpty ||
          category.isEmpty ||
          genderCategory.isEmpty ||
          (size is String && size.isEmpty) ||
          (size is List && size.isEmpty) ||
          color.isEmpty ||
          price <= 0) {
        return "Error: All fields are required";
      }

      if (images.isEmpty) {
        return "Error: At least one image is required";
      }

      // Process all images - not just the first one
      List<String> imageBase64List = [];

      print("Processing ${images.length} images...");

      // Process each image individually
      for (int i = 0; i < images.length; i++) {
        try {
          print("Processing image ${i + 1}/${images.length}");

          // Get image bytes and resize/compress them
          final bytes = await images[i].readAsBytes();
          print(
              "Image ${i + 1} size before processing: ${(bytes.length / 1024).toStringAsFixed(2)} KB");

          // Resize and compress the image to reduce payload size
          final Uint8List processedImageBytes =
              await _resizeAndCompressImage(bytes);
          print(
              "Image ${i + 1} size after resize: ${(processedImageBytes.length / 1024).toStringAsFixed(2)} KB");

          // Convert to base64 with a reasonable size
          String base64String = base64Encode(processedImageBytes);
          print(
              "Image ${i + 1} base64 length: ${(base64String.length / 1024).toStringAsFixed(2)} KB");

          // Check if still too large (over 200KB after processing)
          if (base64String.length > 200 * 1024) {
            print("Image ${i + 1} too large after processing, truncating...");
            // Further reduce quality by taking only a portion
            base64String = base64String.substring(0, 200 * 1024);
          }

          // Add this image to our list
          imageBase64List.add(base64String);
          print("Successfully processed image ${i + 1}");

          // If we have 5 or more images already, stop processing to avoid document size limits
          if (imageBase64List.length >= 5) {
            print(
                "Limiting to 5 images to prevent exceeding Firestore document size");
            break;
          }
        } catch (e) {
          print("Error processing image ${i + 1}: $e");
          // Continue with other images if one fails
          continue;
        }
      }

      print("Successfully processed ${imageBase64List.length} images in total");

      if (imageBase64List.isEmpty) {
        return "Error: Could not process any images. Please try with smaller images.";
      }

      // Handle sizes properly based on input type
      List<String> sizesList;
      if (size is List) {
        // If size is already a List, use it directly
        sizesList = List<String>.from(size);
      } else if (size is String) {
        // Convert comma-separated size string to list of sizes
        sizesList = size
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        // Fallback for unexpected type
        sizesList = [];
      }

      // Product data with all processed images and gender category
      final Map<String, dynamic> productData = {
        'title': title,
        'description': description,
        'sizes': sizesList, // Store as array of sizes
        'colors': color,
        'category': category,
        'genderCategory': genderCategory, // Add gender category
        'price': price,
        'imageURLs': imageBase64List, // Store ALL processed images
        'addedByAdmin': Timestamp.now(),
      };

      // Try to add the product with retry
      DocumentReference? productRef;
      int retries = 0;

      while (retries < 3 && productRef == null) {
        try {
          productRef = await _firestore
              .collection('admin_products')
              .add(productData)
              .timeout(Duration(seconds: 20)); // Add timeout to each attempt
        } catch (e) {
          print("Attempt ${retries + 1} failed: $e");
          retries++;

          if (retries >= 3) {
            return "Error: Failed to add product after multiple attempts. Please check your connection.";
          }

          // Wait before retry
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (productRef != null) {
        return "Product added successfully!";
      } else {
        return "Error: Failed to add product. Please try again.";
      }
    } catch (e) {
      print("Error in addProduct: ${e.toString()}");
      // Simplified error for user
      return "Error: Failed to add product. Please check your connection and try again.";
    }
  }

  // Simplified image conversion that won't throw errors
  Future<String> _convertImageToBase64(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Error converting image: $e");
      return ""; // Return empty string instead of throwing
    }
  }
}
