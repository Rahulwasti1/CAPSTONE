import 'dart:convert'; // For base64 encoding
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import 'package:capstone/service/asset_organizer_service.dart';

class AddingProduct {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Category to asset folder mapping
  final Map<String, String> categoryAssetPaths = {
    'Apparel': 'assets/effects/apparel/',
    'Shoes': 'assets/effects/shoes/',
    'Watches': 'assets/effects/watches/',
    'Ornaments': 'assets/effects/ornaments/',
    'Sunglasses': 'assets/effects/sunglasses/',
  };

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

      // Organize images into category-specific asset folders
      print("📁 Organizing ${images.length} images for category: $category");

      List<String> organizedImagePaths =
          await AssetOrganizerService.saveImagesToDocuments(
        images: images,
        category: category,
        productTitle: title,
        colors: color,
        productId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      if (organizedImagePaths.isEmpty) {
        return "Error: Could not organize any images. Please try again.";
      }

      // Also process images for base64 storage as fallback
      List<String> imageBase64List = [];
      print("Processing ${images.length} images for base64 storage...");

      // Process each image individually for base64 fallback
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

      // Product data with organized asset paths and base64 fallback
      final Map<String, dynamic> productData = {
        'title': title,
        'description': description,
        'sizes': sizesList, // Store as array of sizes
        'colors': color,
        'category': category,
        'genderCategory': genderCategory, // Add gender category
        'price': price,
        'imageURLs': imageBase64List, // Store base64 images as fallback
        'assetPaths':
            organizedImagePaths, // Store organized asset paths for AR try-on
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

  // Method to organize and save images to category-specific asset folders
  Future<List<String>> organizeProductImages({
    required List<XFile> images,
    required String category,
    required String productTitle,
    required List<String> colors,
  }) async {
    List<String> organizedImagePaths = [];

    try {
      // Get the asset folder path for the category
      String assetFolderPath =
          categoryAssetPaths[category] ?? 'assets/effects/general/';

      // Create a clean product name for file naming
      String cleanProductName = _cleanProductName(productTitle);

      // Process each image
      for (int i = 0; i < images.length; i++) {
        try {
          // Read image bytes
          final Uint8List imageBytes = await images[i].readAsBytes();

          // Resize and compress the image (for optimization)
          await _resizeAndCompressImage(imageBytes);

          // Generate filename based on product and color
          String filename;
          if (colors.isNotEmpty && i < colors.length) {
            // Map color code to color name for filename
            String colorName = _getColorNameFromCode(colors[i]);
            filename = '${cleanProductName}($colorName).png';
          } else {
            filename = '${cleanProductName}_${i + 1}.png';
          }

          // Create the full asset path
          String fullAssetPath = '$assetFolderPath$filename';

          // Store the asset path for AR try-on
          organizedImagePaths.add(fullAssetPath);

          // Log the organization
          print('📁 Organized image: $fullAssetPath');
        } catch (e) {
          print('❌ Error processing image ${i + 1}: $e');
          continue;
        }
      }

      print(
          '✅ Successfully organized ${organizedImagePaths.length} images for category: $category');
      return organizedImagePaths;
    } catch (e) {
      print('❌ Error organizing images: $e');
      return [];
    }
  }

  // Helper method to clean product name for file naming
  String _cleanProductName(String productTitle) {
    return productTitle
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '') // Remove spaces
        .trim();
  }

  // Helper method to get color name from color code
  String _getColorNameFromCode(String colorCode) {
    final Map<String, String> colorMap = {
      '4278190080': 'Black',
      '4294967295': 'White',
      '4294198070': 'Blue',
      '4280391411': 'Blue',
      '4294901760': 'Red',
      '4278255360': 'Green',
      '4294934352': 'Yellow',
      '4294902015': 'Pink',
      '4289797371': 'Purple',
      '4294945600': 'Orange',
      '4286611584': 'Brown',
      '4288585374': 'Grey',
      '4278255615': 'Cyan',
    };

    return colorMap[colorCode] ?? 'Default';
  }

  // Method to create asset directory structure (for development purposes)
  Future<void> createAssetDirectoryStructure() async {
    try {
      // This would typically be done during app build/development
      // For now, we'll just log the structure that should be created
      print('📂 Asset directory structure:');
      categoryAssetPaths.forEach((category, path) {
        print('   $category: $path');
      });
    } catch (e) {
      print('❌ Error creating asset directory structure: $e');
    }
  }
}
