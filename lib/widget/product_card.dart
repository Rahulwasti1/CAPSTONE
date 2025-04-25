import 'dart:convert'; // For Base64 decoding
import 'package:flutter/material.dart';
import 'package:capstone/constants/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
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
                height: 110.h,
                width: double.infinity,
                color: Colors.grey[200],
                child: _buildProductImage(imagesList),
              ),
            ),

            // Product Details
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  SizedBox(
                    height: 32.h,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Price
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C4024),
                    ),
                  ),
                ],
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
        // Handle string - could be a single image or delimited
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

    // Remove any duplicates and empty strings
    return allImages.where((img) => img.trim().isNotEmpty).toSet().toList();
  }

  // Helper method to build product image with proper error handling
  Widget _buildProductImage(List<String> imagesList) {
    if (imagesList.isEmpty) {
      return _buildFallbackImage();
    }

    // Try to display the first image in the list, with fallbacks
    return _tryDisplayImage(imagesList, 0);
  }

  Widget _tryDisplayImage(List<String> images, int index) {
    if (index >= images.length) {
      return _buildFallbackImage();
    }

    try {
      return Image.memory(
        base64Decode(images[index]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading image: $error');
          // Try the next image if this one fails
          return _tryDisplayImage(images, index + 1);
        },
      );
    } catch (e) {
      developer.log('Error decoding image: $e');
      // Try the next image if this one fails
      return _tryDisplayImage(images, index + 1);
    }
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 4.h),
          Text(
            'No image',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[500],
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
                    color: Color(0xFF6C4024),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.r),
                topRight: Radius.circular(10.r),
              ),
              child: Container(
                height: 110.h,
                width: double.infinity,
                color: Colors.grey[200],
                child: _buildProductImage(imagesList),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 6.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 28.h,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C4024),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _extractAllImages() {
    List<String> allImages = [];
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
    if (product['base64Image'] != null &&
        product['base64Image'].toString().isNotEmpty) {
      allImages.add(product['base64Image'].toString());
    }
    return allImages.where((img) => img.trim().isNotEmpty).toSet().toList();
  }

  Widget _buildProductImage(List<String> imagesList) {
    if (imagesList.isEmpty) {
      return _buildFallbackImage();
    }
    return _tryDisplayImage(imagesList, 0);
  }

  Widget _tryDisplayImage(List<String> images, int index) {
    if (index >= images.length) {
      return _buildFallbackImage();
    }
    try {
      return Image.memory(
        base64Decode(images[index]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _tryDisplayImage(images, index + 1);
        },
      );
    } catch (e) {
      return _tryDisplayImage(images, index + 1);
    }
  }

  Widget _buildFallbackImage() {
    return Center(
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[400],
        size: 24.sp,
      ),
    );
  }
}
