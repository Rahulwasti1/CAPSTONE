import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:capstone/providers/cart_provider.dart';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: "My Cart"),
            Expanded(
              child: Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.items.isEmpty) {
                    return Center(
                      child: Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: cart.items.length,
                          itemBuilder: (ctx, i) {
                            final cartItem = cart.items[i];
                            return CartItemWidget(cartItem: cartItem);
                          },
                        ),
                      ),
                      CartSummary(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;

  const CartItemWidget({
    Key? key,
    required this.cartItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: 80.w,
              height: 80.w,
              child: _buildProductImage(cartItem.imageUrl),
            ),
          ),
          SizedBox(width: 12.w),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Color: ${cartItem.color}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Size: ${cartItem.size}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs ${cartItem.price}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    QuantityControls(cartItem: cartItem),
                  ],
                ),
              ],
            ),
          ),
          // Delete Button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red[400],
              size: 20.sp,
            ),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false)
                  .removeItem(cartItem.id, cartItem.size, cartItem.color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildFallbackImage();
    }

    // Check if it's a network URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          developer.log("Network image error in cart: $error");
          return _buildFallbackImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // Check if it's a base64 image
    try {
      String processedImageUrl = imageUrl;
      if (imageUrl.contains('base64,')) {
        processedImageUrl = imageUrl.split('base64,')[1];
      }

      // Validate and pad base64 string if needed
      String sanitized = processedImageUrl.trim();
      int padLength = 4 - sanitized.length % 4;
      if (padLength < 4) {
        sanitized = sanitized + ('=' * padLength);
      }

      final Uint8List decodedBytes = base64Decode(sanitized);
      return Image.memory(
        decodedBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          developer.log("Base64 image error in cart: $error");
          return _buildFallbackImage();
        },
      );
    } catch (e) {
      developer.log("Image decode error in cart: $e");

      // Try as asset image
      try {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            developer.log("Asset image error in cart: $error");
            return _buildFallbackImage();
          },
        );
      } catch (assetError) {
        developer.log("Asset image failed in cart: $assetError");
        return _buildFallbackImage();
      }
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: 24.sp,
      ),
    );
  }
}

class QuantityControls extends StatelessWidget {
  final CartItem cartItem;

  const QuantityControls({
    Key? key,
    required this.cartItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false)
                  .decrementQuantity(
                      cartItem.id, cartItem.size, cartItem.color);
            },
          ),
          Container(
            width: 32.w,
            alignment: Alignment.center,
            child: Text(
              '${cartItem.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false)
                  .incrementQuantity(
                      cartItem.id, cartItem.size, cartItem.color);
            },
          ),
        ],
      ),
    );
  }
}

class CartSummary extends StatelessWidget {
  const CartSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Discount Code Input
          Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Discount Code',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: CustomColors.secondaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Price Summary
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Column(
                children: [
                  _buildSummaryRow(
                      'Subtotal', 'Rs ${cart.totalAmount.toStringAsFixed(2)}'),
                  SizedBox(height: 8.h),
                  _buildSummaryRow(
                      'Total', 'Rs ${cart.totalAmount.toStringAsFixed(2)}',
                      isBold: true),
                ],
              );
            },
          ),
          SizedBox(height: 16.h),
          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () {
                // Handle checkout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColors.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? CustomColors.secondaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}
