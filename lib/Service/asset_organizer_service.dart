import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AssetOrganizerService {
  // Category to asset folder mapping
  static const Map<String, String> categoryAssetPaths = {
    'Apparel': 'assets/effects/apparel/',
    'Shoes': 'assets/effects/shoes/',
    'Watches': 'assets/effects/watches/',
    'Ornaments': 'assets/effects/ornaments/',
    'Sunglasses': 'assets/effects/sunglasses/',
    'Headwear': 'assets/effects/hats/',
  };

  // Category to documents folder mapping (for runtime storage)
  static const Map<String, String> categoryDocumentPaths = {
    'Apparel': 'product_images/apparel/',
    'Shoes': 'product_images/shoes/',
    'Watches': 'product_images/watches/',
    'Ornaments': 'product_images/ornaments/',
    'Sunglasses': 'product_images/sunglasses/',
    'Headwear': 'product_images/headwear/',
  };

  // Method to save images to app documents directory (runtime storage)
  static Future<List<String>> saveImagesToDocuments({
    required List<XFile> images,
    required String category,
    required String productTitle,
    required List<String> colors,
    required String productId,
  }) async {
    List<String> savedPaths = [];

    try {
      // Get app documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // Get the document folder path for the category
      String docFolderPath =
          categoryDocumentPaths[category] ?? 'product_images/general/';
      String fullDocPath = path.join(appDocDir.path, docFolderPath);

      // Create directory if it doesn't exist
      Directory docDir = Directory(fullDocPath);
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
        print('📁 Created directory: $fullDocPath');
      }

      // Create a clean product name for file naming
      String cleanProductName = _cleanProductName(productTitle);

      // Process each image
      for (int i = 0; i < images.length; i++) {
        try {
          // Read image bytes
          final Uint8List imageBytes = await images[i].readAsBytes();

          // Resize and compress the image for better performance
          final Uint8List processedImageBytes =
              await _resizeAndCompressImage(imageBytes);

          // Generate filename based on product and color
          String filename;
          if (colors.isNotEmpty && i < colors.length) {
            String colorName = _getColorNameFromCode(colors[i]);
            filename = '${cleanProductName}($colorName).png';
          } else {
            filename = '${cleanProductName}_${i + 1}.png';
          }

          // Create the full file path
          String fullFilePath = path.join(fullDocPath, filename);

          // Save the image file
          File imageFile = File(fullFilePath);
          await imageFile.writeAsBytes(processedImageBytes);

          // Store the full file path for later retrieval
          savedPaths.add(fullFilePath);

          print('💾 Saved image: $fullFilePath');
        } catch (e) {
          print('❌ Error saving image ${i + 1}: $e');
          continue;
        }
      }

      print(
          '✅ Successfully saved ${savedPaths.length} images to documents for category: $category');
      return savedPaths;
    } catch (e) {
      print('❌ Error saving images to documents: $e');
      return [];
    }
  }

  // Method to get organized images for a product
  static Future<List<File>> getProductImages({
    required String category,
    required String productId,
    required String productTitle,
    String? selectedColor,
  }) async {
    List<File> productImages = [];

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      String docFolderPath =
          categoryDocumentPaths[category] ?? 'product_images/general/';
      String fullDocPath = path.join(appDocDir.path, docFolderPath);

      Directory docDir = Directory(fullDocPath);
      if (!await docDir.exists()) {
        return productImages;
      }

      String cleanProductName = _cleanProductName(productTitle);

      // List all files in the category directory
      await for (FileSystemEntity entity in docDir.list()) {
        if (entity is File && _isImageFile(entity.path)) {
          String filename = path.basename(entity.path);

          // Check if this image belongs to the product
          if (filename.toLowerCase().contains(cleanProductName.toLowerCase())) {
            // If color is specified, try to match it
            if (selectedColor != null && selectedColor.isNotEmpty) {
              if (filename
                  .toLowerCase()
                  .contains(selectedColor.toLowerCase())) {
                productImages.insert(0, entity); // Priority for color match
              } else {
                productImages.add(entity);
              }
            } else {
              productImages.add(entity);
            }
          }
        }
      }

      print(
          '📋 Found ${productImages.length} images for product: $productTitle');
      return productImages;
    } catch (e) {
      print('❌ Error getting product images: $e');
      return [];
    }
  }

  // Method to get all images in a category
  static Future<List<File>> getImagesInCategory(String category) async {
    List<File> imageFiles = [];

    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      String docFolderPath =
          categoryDocumentPaths[category] ?? 'product_images/general/';
      String fullDocPath = path.join(appDocDir.path, docFolderPath);

      Directory docDir = Directory(fullDocPath);
      if (await docDir.exists()) {
        await for (FileSystemEntity entity in docDir.list()) {
          if (entity is File && _isImageFile(entity.path)) {
            imageFiles.add(entity);
          }
        }
      }

      print('📋 Found ${imageFiles.length} images in $category category');
      return imageFiles;
    } catch (e) {
      print('❌ Error listing images in category $category: $e');
      return [];
    }
  }

  // Method to resize and compress image
  static Future<Uint8List> _resizeAndCompressImage(Uint8List imageBytes) async {
    // For now, return original bytes
    // In a production app, you might want to use image compression libraries
    return imageBytes;
  }

  // Helper method to clean product name for file naming
  static String _cleanProductName(String productTitle) {
    return productTitle
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '') // Remove spaces
        .trim();
  }

  // Helper method to get color name from color code
  static String _getColorNameFromCode(String colorCode) {
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

  // Method to create directory structure in documents
  static Future<void> createDocumentDirectoryStructure() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      print('📂 Creating document directory structure...');

      for (String category in categoryDocumentPaths.keys) {
        String docPath = categoryDocumentPaths[category]!;
        String fullPath = path.join(appDocDir.path, docPath);

        Directory dir = Directory(fullPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
          print('✅ Created: $fullPath');
        } else {
          print('📁 Already exists: $fullPath');
        }
      }

      print('🎉 Document directory structure ready!');
    } catch (e) {
      print('❌ Error creating document directory structure: $e');
    }
  }

  // Helper method to check if file is an image
  static bool _isImageFile(String filePath) {
    String extension = path.extension(filePath).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp']
        .contains(extension);
  }

  // Method to clear all product images (for testing/debugging)
  static Future<void> clearAllProductImages() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      String productImagesPath = path.join(appDocDir.path, 'product_images');

      Directory productImagesDir = Directory(productImagesPath);
      if (await productImagesDir.exists()) {
        await productImagesDir.delete(recursive: true);
        print('🗑️ Cleared all product images');
      }
    } catch (e) {
      print('❌ Error clearing product images: $e');
    }
  }

  // Method to get statistics about stored images
  static Future<Map<String, int>> getImageStatistics() async {
    Map<String, int> stats = {};

    try {
      for (String category in categoryDocumentPaths.keys) {
        List<File> images = await getImagesInCategory(category);
        stats[category] = images.length;
      }

      print('📊 Image statistics: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting image statistics: $e');
      return {};
    }
  }
}
