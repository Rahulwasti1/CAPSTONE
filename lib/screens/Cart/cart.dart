import 'package:capstone/providers/cart_provider.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:capstone/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer' as developer;

class UserCart extends StatelessWidget {
  const UserCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                UserAppbar(text: 'Cart'),
                Expanded(child: _buildCartContent(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartContent(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    // Get items directly as they're already a list
    final List<CartItem> cartItems = cartProvider.items;

    if (cartItems.isEmpty) {
      return _buildEmptyCart(context);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItem(context, item, cartProvider);
            },
          ),
        ),
        _buildCartSummary(context, cartProvider),
      ],
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 64.sp,
              color: theme.iconTheme.color?.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineSmall?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add products to your cart to see them here',
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade600, Colors.brown.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserCategories(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Continue Shopping',
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

  Widget _buildCartItem(
      BuildContext context, CartItem item, CartProvider cartProvider) {
    final theme = Theme.of(context);
    final String itemTitle =
        item.title.isNotEmpty ? item.title : 'Unknown Product';
    final String itemImageUrl = item.imageUrl;
    final int itemQuantity = item.quantity > 0 ? item.quantity : 1;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with enhanced styling
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: item.imageUrl.isNotEmpty
                  ? _buildCartImage(item.imageUrl, theme)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[200]!,
                            theme.brightness == Brightness.dark
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 28.sp,
                              color: theme.iconTheme.color?.withOpacity(0.5),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'No image',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemTitle,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              if (item.color.isNotEmpty) ...[
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  decoration: BoxDecoration(
                                    color: _getColorFromString(item.color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  item.color,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                              if (item.size.isNotEmpty) ...[
                                SizedBox(width: 12.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[700]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    item.size,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Rs ${item.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.brown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[600],
                          size: 20.sp,
                        ),
                        onPressed: () {
                          cartProvider.removeItem(
                              item.id, item.size, item.color);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Item removed from cart',
                                style: TextStyle(color: Colors.white),
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor:
                                  theme.brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[700],
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: Colors.brown,
                                onPressed: () {
                                  cartProvider.addItem(
                                    productId: item.id,
                                    title: itemTitle,
                                    price: item.price,
                                    imageUrl: itemImageUrl,
                                    color: item.color,
                                    size: item.size,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        padding: EdgeInsets.all(8.r),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        context: context,
                        icon: Icons.remove,
                        onPressed: () {
                          cartProvider.decrementQuantity(
                              item.id, item.size, item.color);
                        },
                      ),
                      Container(
                        constraints: BoxConstraints(minWidth: 50.w),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          '$itemQuantity',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        context: context,
                        icon: Icons.add,
                        onPressed: () {
                          cartProvider.incrementQuantity(
                              item.id, item.size, item.color);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          padding: EdgeInsets.all(8.r),
          child: Icon(
            icon,
            size: 18.sp,
            color: theme.iconTheme.color,
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          _buildSummaryRow(
            context,
            'Subtotal',
            'Rs ${cartProvider.totalAmount.toStringAsFixed(2)}',
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            context,
            'Shipping',
            'Rs ${cartProvider.deliveryFee.toStringAsFixed(2)}',
          ),
          SizedBox(height: 12.h),
          if (cartProvider.discount > 0) ...[
            _buildSummaryRow(
              context,
              'Discount',
              '-Rs ${cartProvider.discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
            SizedBox(height: 12.h),
          ],
          Divider(
            color: theme.dividerColor.withOpacity(0.3),
            thickness: 1,
          ),
          SizedBox(height: 12.h),
          _buildSummaryRow(
            context,
            'Total',
            'Rs ${cartProvider.finalAmount.toStringAsFixed(2)}',
            isBold: true,
          ),
          SizedBox(height: 24.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade600, Colors.brown.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (cartProvider.items.isNotEmpty) {
                  _showCheckoutDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Your cart is empty',
                        style: TextStyle(color: Colors.white),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[700],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18.sp : 15.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold
                ? theme.textTheme.titleLarge?.color
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18.sp : 15.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isDiscount
                ? Colors.green[600]
                : isBold
                    ? Colors.brown
                    : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Checkout',
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This is a demo app. In a real app, this would proceed to the payment screen.',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade600, Colors.brown.shade800],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextButton(
                onPressed: () {
                  final cartProvider =
                      Provider.of<CartProvider>(context, listen: false);
                  cartProvider.clearCart();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order placed successfully!',
                        style: TextStyle(color: Colors.white),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(
                  'Place Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartImage(String imageUrl, ThemeData theme) {
    // Check if it's a network URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          developer.log("Network image error in cart: $error");
          return _buildImageFallback(theme);
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
              strokeWidth: 2,
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
          return _buildImageFallback(theme);
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
            return _buildImageFallback(theme);
          },
        );
      } catch (assetError) {
        developer.log("Asset image failed in cart: $assetError");
        return _buildImageFallback(theme);
      }
    }
  }

  Widget _buildImageFallback(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[200]!,
            theme.brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[300]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 28.sp,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
            SizedBox(height: 4.h),
            Text(
              'Image not\navailable',
              style: TextStyle(
                fontSize: 10.sp,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
