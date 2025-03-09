import 'dart:convert'; // For Base64 decoding
import 'package:flutter/material.dart';
import 'package:capstone/constants/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extract product data
    String title = product['title'] ?? 'Unknown Product';
    String description = product['description'] ?? 'No description';

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

    // Handle colors
    List<String> colors = [];
    if (product['colors'] != null) {
      if (product['colors'] is List) {
        colors = List<String>.from(product['colors']);
      }
    }

    // Handle image
    List<String> imageURLs = [];
    if (product['imageURLs'] != null && product['imageURLs'] is List) {
      imageURLs = List<String>.from(product['imageURLs']);
    }

    String? base64Image = imageURLs.isNotEmpty ? imageURLs[0] : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180.w,
        margin: EdgeInsets.only(right: 0.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.r),
                topRight: Radius.circular(15.r),
              ),
              child: Container(
                height: 170.h,
                width: double.infinity,
                color: Colors.grey[200],
                child: base64Image != null
                    ? Image.memory(
                        base64Decode(base64Image),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          );
                        },
                      )
                    : Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
            ),

            // Product Details
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Color options
                  // if (colors.isNotEmpty)
                  //   Row(
                  //     children: colors.take(3).map((colorCode) {
                  //       return Container(
                  //         height: 12.h,
                  //         width: 25.w,
                  //         margin: EdgeInsets.only(right: 4.w),
                  //         decoration: BoxDecoration(
                  //           color: Color(int.parse(colorCode)),
                  //           shape: BoxShape.circle,
                  //         ),
                  //       );
                  //     }).toList(),
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Grid view for products
class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>)? onProductTap;

  const ProductGrid({
    Key? key,
    required this.products,
    this.onProductTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onTap: onProductTap != null
              ? () => onProductTap!(products[index])
              : null,
        );
      },
    );
  }
}
