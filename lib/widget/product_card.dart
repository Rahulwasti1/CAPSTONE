import 'dart:convert'; // For Base64 decoding
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;
import 'package:camera/camera.dart';
import 'package:capstone/screens/ar/ar_hats_screen.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract product data
    String title = product['title'] ?? 'Unknown Product';

    // Handle price (could be int, double, or string in Firestore)
    var priceValue = product['price'];
    String price = 'Price not available';
    if (priceValue != null) {
      if (priceValue is int || priceValue is double) {
        price = 'Rs ${priceValue.toString()}';
      } else if (priceValue is String) {
        price = 'Rs $priceValue';
      }
    }

    // Extract all possible images
    List<String> imagesList = _extractAllImages();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.r),
                topRight: Radius.circular(10.r),
              ),
              child: Container(
                height: 120.h, // Slightly increased height
                width: double.infinity,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                child: _buildProductImage(imagesList, context),
              ),
            ),

            // Product Details - Flexible layout
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - Takes most available space
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp, // Good readable size
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.titleMedium?.color,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Small spacing
                    SizedBox(height: 4.h),

                    // Price - Fixed at bottom
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 13.sp, // Good readable size
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extract all possible images from the product data
  List<String> _extractAllImages() {
    List<String> allImages = [];

    // Case 1: Check 'imageURLs' field (most common)
    if (product['imageURLs'] != null) {
      if (product['imageURLs'] is List) {
        allImages.addAll(List<String>.from(product['imageURLs']));
      } else if (product['imageURLs'] is String) {
        String imgStr = product['imageURLs'] as String;
        if (imgStr.contains(';')) {
          allImages.addAll(imgStr.split(';').where((i) => i.isNotEmpty));
        } else if (imgStr.contains(',')) {
          allImages.addAll(imgStr.split(',').where((i) => i.isNotEmpty));
        } else if (imgStr.contains('|')) {
          allImages.addAll(imgStr.split('|').where((i) => i.isNotEmpty));
        } else if (imgStr.isNotEmpty) {
          allImages.add(imgStr);
        }
      }
    }

    // Case 2: Check 'images' field
    if (product['images'] != null) {
      if (product['images'] is List) {
        allImages.addAll(List<String>.from(product['images']));
      } else if (product['images'] is String) {
        String imgStr = product['images'] as String;
        // Try as delimited string
        if (imgStr.contains(';')) {
          allImages.addAll(imgStr.split(';').where((i) => i.isNotEmpty));
        } else if (imgStr.contains(',')) {
          allImages.addAll(imgStr.split(',').where((i) => i.isNotEmpty));
        } else if (imgStr.contains('|')) {
          allImages.addAll(imgStr.split('|').where((i) => i.isNotEmpty));
        } else if (imgStr.isNotEmpty) {
          allImages.add(imgStr);
        }
      }
    }

    // Case 3: Check individual fields
    if (product['imageUrl'] != null &&
        product['imageUrl'].toString().isNotEmpty) {
      allImages.add(product['imageUrl'].toString());
    }

    if (product['image'] != null && product['image'].toString().isNotEmpty) {
      allImages.add(product['image'].toString());
    }

    if (product['base64Image'] != null &&
        product['base64Image'].toString().isNotEmpty) {
      allImages.add(product['base64Image'].toString());
    }

    // Case 4: Check 'downloadURL' field (common in Firebase Storage use cases)
    if (product['downloadURL'] != null) {
      if (product['downloadURL'] is List) {
        allImages.addAll(List<String>.from(product['downloadURL']));
      } else if (product['downloadURL'] is String &&
          product['downloadURL'].toString().isNotEmpty) {
        allImages.add(product['downloadURL'].toString());
      }
    }

    // Case 5: Check 'downloadUrl' field (alternate spelling)
    if (product['downloadUrl'] != null) {
      if (product['downloadUrl'] is List) {
        allImages.addAll(List<String>.from(product['downloadUrl']));
      } else if (product['downloadUrl'] is String &&
          product['downloadUrl'].toString().isNotEmpty) {
        allImages.add(product['downloadUrl'].toString());
      }
    }

    // Case 6: Check 'imageURL' field (singular)
    if (product['imageURL'] != null) {
      if (product['imageURL'] is List) {
        allImages.addAll(List<String>.from(product['imageURL']));
      } else if (product['imageURL'] is String &&
          product['imageURL'].toString().isNotEmpty) {
        allImages.add(product['imageURL'].toString());
      }
    }

    // Remove any duplicates and empty strings
    return allImages.where((img) => img.trim().isNotEmpty).toSet().toList();
  }

  // Helper method to build product image with proper error handling
  Widget _buildProductImage(List<String> imagesList, BuildContext context) {
    if (imagesList.isEmpty) {
      return _buildFallbackImage(context);
    }

    // Try to display the first image in the list, with fallbacks
    return _tryDisplayImage(imagesList, 0, context);
  }

  Widget _tryDisplayImage(
      List<String> images, int index, BuildContext context) {
    if (index >= images.length) {
      return _buildFallbackImage(context);
    }

    String imageUrl = images[index];

    // First check if it's a URL (starts with http/https)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit
            .contain, // Changed from cover to contain for better image visibility
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading network image: $error');
          return _tryDisplayImage(images, index + 1, context);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.brown,
              strokeWidth: 2.0,
            ),
          );
        },
      );
    }

    // Try to decode as base64
    try {
      // Check if it's a valid base64 string
      // Some base64 strings might have data:image prefix, remove that first
      if (imageUrl.contains('base64,')) {
        imageUrl = imageUrl.split('base64,')[1];
      }

      // Validate the base64 string and pad if needed
      String sanitized = imageUrl.trim();
      int padLength = 4 - sanitized.length % 4;
      if (padLength < 4) {
        sanitized = sanitized + ('=' * padLength);
      }

      // Now try to decode it
      Uint8List decodedBytes = base64Decode(sanitized);
      return Image.memory(
        decodedBytes,
        fit: BoxFit
            .contain, // Changed from cover to contain for better image visibility
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error displaying base64 image: $error');
          return _tryDisplayImage(images, index + 1, context);
        },
      );
    } catch (e) {
      developer.log('Error decoding base64 image: $e');
      return _tryDisplayImage(images, index + 1, context);
    }
  }

  Widget _buildFallbackImage(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30.sp,
            color: theme.iconTheme.color?.withOpacity(0.5),
          ),
          SizedBox(height: 4.h),
          Text(
            'No image',
            style: TextStyle(
              fontSize: 10.sp,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for showing products in a horizontal list
class HorizontalProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onProductTap;
  final String title;

  const HorizontalProductList({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to view all products
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemBuilder: (context, index) {
              return Container(
                width: 160.w,
                margin: EdgeInsets.only(right: 16.w),
                child: ProductCard(
                  product: products[index],
                  onTap: () => onProductTap(products[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FlashSaleProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const FlashSaleProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title = product['title'] ?? 'Unknown Product';
    var priceValue = product['price'];
    String price = 'Price not available';
    if (priceValue != null) {
      if (priceValue is int || priceValue is double) {
        price = 'Rs ${priceValue.toString()}';
      } else if (priceValue is String) {
        price = 'Rs $priceValue';
      }
    }

    List<String> imagesList = _extractAllImages();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Takes up most of the space
            Expanded(
              flex: 7, // Increased flex for more image space
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  topRight: Radius.circular(10.r),
                ),
                child: Container(
                  width: double.infinity,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  child: _buildProductImage(imagesList, context),
                ),
              ),
            ),

            // Product Details - Flexible space that adapts
            Expanded(
              flex: 3, // Reduced flex for text area
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - Takes available space
                    Expanded(
                      flex: 2,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.sp, // Good readable size
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.titleMedium?.color,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Small spacing
                    SizedBox(height: 2.h),

                    // Price and Try On Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Expanded(
                          child: Text(
                            price,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHatAR(BuildContext context) async {
    try {
      // Import camera package
      final cameras = await availableCameras();

      if (!context.mounted) return;

      // Get product image - try to use the actual product image if available
      String productImage = 'assets/effects/hats/hats.png'; // Default fallback

      // Try to get the actual product image
      List<String> imagesList = _extractAllImages();
      if (imagesList.isNotEmpty) {
        productImage = imagesList.first;
      }

      // Navigate to Hat AR screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARHatsScreen(
            cameras: cameras,
            productImage: productImage,
            productTitle: product['title'] ?? 'Hat',
            productId: product['id'],
            productData: product,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera not available: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extract all possible images from the product data
  List<String> _extractAllImages() {
    List<String> allImages = [];

    // Case 1: Check 'imageURLs' field (most common)
    if (product['imageURLs'] != null) {
      if (product['imageURLs'] is List) {
        allImages.addAll(List<String>.from(product['imageURLs']));
      } else if (product['imageURLs'] is String) {
        String imgStr = product['imageURLs'] as String;
        if (imgStr.contains(';')) {
          allImages.addAll(imgStr.split(';').where((i) => i.isNotEmpty));
        } else if (imgStr.contains(',')) {
          allImages.addAll(imgStr.split(',').where((i) => i.isNotEmpty));
        } else if (imgStr.contains('|')) {
          allImages.addAll(imgStr.split('|').where((i) => i.isNotEmpty));
        } else if (imgStr.isNotEmpty) {
          allImages.add(imgStr);
        }
      }
    }

    // Case 2: Check 'images' field
    if (product['images'] != null) {
      if (product['images'] is List) {
        allImages.addAll(List<String>.from(product['images']));
      } else if (product['images'] is String) {
        String imgStr = product['images'] as String;
        // Try as delimited string
        if (imgStr.contains(';')) {
          allImages.addAll(imgStr.split(';').where((i) => i.isNotEmpty));
        } else if (imgStr.contains(',')) {
          allImages.addAll(imgStr.split(',').where((i) => i.isNotEmpty));
        } else if (imgStr.contains('|')) {
          allImages.addAll(imgStr.split('|').where((i) => i.isNotEmpty));
        } else if (imgStr.isNotEmpty) {
          allImages.add(imgStr);
        }
      }
    }

    // Case 3: Check individual fields
    if (product['imageUrl'] != null &&
        product['imageUrl'].toString().isNotEmpty) {
      allImages.add(product['imageUrl'].toString());
    }

    if (product['image'] != null && product['image'].toString().isNotEmpty) {
      allImages.add(product['image'].toString());
    }

    if (product['base64Image'] != null &&
        product['base64Image'].toString().isNotEmpty) {
      allImages.add(product['base64Image'].toString());
    }

    // Case 4: Check 'downloadURL' field (common in Firebase Storage use cases)
    if (product['downloadURL'] != null) {
      if (product['downloadURL'] is List) {
        allImages.addAll(List<String>.from(product['downloadURL']));
      } else if (product['downloadURL'] is String &&
          product['downloadURL'].toString().isNotEmpty) {
        allImages.add(product['downloadURL'].toString());
      }
    }

    // Case 5: Check 'downloadUrl' field (alternate spelling)
    if (product['downloadUrl'] != null) {
      if (product['downloadUrl'] is List) {
        allImages.addAll(List<String>.from(product['downloadUrl']));
      } else if (product['downloadUrl'] is String &&
          product['downloadUrl'].toString().isNotEmpty) {
        allImages.add(product['downloadUrl'].toString());
      }
    }

    // Case 6: Check 'imageURL' field (singular)
    if (product['imageURL'] != null) {
      if (product['imageURL'] is List) {
        allImages.addAll(List<String>.from(product['imageURL']));
      } else if (product['imageURL'] is String &&
          product['imageURL'].toString().isNotEmpty) {
        allImages.add(product['imageURL'].toString());
      }
    }

    // Remove any duplicates and empty strings
    return allImages.where((img) => img.trim().isNotEmpty).toSet().toList();
  }

  // Helper method to build product image with proper error handling
  Widget _buildProductImage(List<String> imagesList, BuildContext context) {
    if (imagesList.isEmpty) {
      return _buildFallbackImage(context);
    }

    // Try to display the first image in the list, with fallbacks
    return _tryDisplayImage(imagesList, 0, context);
  }

  Widget _tryDisplayImage(
      List<String> images, int index, BuildContext context) {
    if (index >= images.length) {
      return _buildFallbackImage(context);
    }

    String imageUrl = images[index];

    // First check if it's a URL (starts with http/https)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit
            .contain, // Changed from cover to contain for better image visibility
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading network image: $error');
          return _tryDisplayImage(images, index + 1, context);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.brown,
              strokeWidth: 2.0,
            ),
          );
        },
      );
    }

    // Try to decode as base64
    try {
      // Check if it's a valid base64 string
      // Some base64 strings might have data:image prefix, remove that first
      if (imageUrl.contains('base64,')) {
        imageUrl = imageUrl.split('base64,')[1];
      }

      // Validate the base64 string and pad if needed
      String sanitized = imageUrl.trim();
      int padLength = 4 - sanitized.length % 4;
      if (padLength < 4) {
        sanitized = sanitized + ('=' * padLength);
      }

      // Now try to decode it
      Uint8List decodedBytes = base64Decode(sanitized);
      return Image.memory(
        decodedBytes,
        fit: BoxFit
            .contain, // Changed from cover to contain for better image visibility
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error displaying base64 image: $error');
          return _tryDisplayImage(images, index + 1, context);
        },
      );
    } catch (e) {
      developer.log('Error decoding base64 image: $e');
      return _tryDisplayImage(images, index + 1, context);
    }
  }

  Widget _buildFallbackImage(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30.sp,
            color: theme.iconTheme.color?.withValues(alpha: 0.5),
          ),
          SizedBox(height: 4.h),
          Text(
            'No image',
            style: TextStyle(
              fontSize: 10.sp,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
