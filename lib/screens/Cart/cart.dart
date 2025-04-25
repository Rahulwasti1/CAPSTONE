import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserCart extends StatelessWidget {
  const UserCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: 'Cart'),
            Expanded(child: _buildCartContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    // Get items as a list from the map
    final List<CartItem> cartItems = cartProvider.items.values.toList();

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add products to your cart to see them here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Navigate to categories page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserCategories(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
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
        ],
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context, CartItem item, CartProvider cartProvider) {
    final String itemTitle =
        item.title.isNotEmpty ? item.title : 'Unknown Product';
    final String itemImageUrl = item.imageUrl;
    final int itemQuantity = item.quantity > 0 ? item.quantity : 1;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: itemImageUrl.isNotEmpty
                  ? Image.network(
                      itemImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 24.sp,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 24.sp,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        itemTitle,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 24.sp,
                      ),
                      onPressed: () {
                        cartProvider.removeItem(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Item removed from cart'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'UNDO',
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
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: () {
                          cartProvider.decrementQuantity(item.id);
                        },
                      ),
                      Container(
                        constraints: BoxConstraints(minWidth: 40.w),
                        alignment: Alignment.center,
                        child: Text(
                          '$itemQuantity',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: () {
                          cartProvider.incrementQuantity(item.id);
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

  Widget _buildQuantityButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Icon(
            icon,
            size: 16.sp,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Subtotal', '\Rs ${cartProvider.totalAmount.toStringAsFixed(2)}'),
          SizedBox(height: 8.h),
          _buildSummaryRow(
              'Shipping', '\Rs ${cartProvider.deliveryFee.toStringAsFixed(2)}'),
          SizedBox(height: 8.h),
          if (cartProvider.discount > 0) ...[
            _buildSummaryRow(
                'Discount', '-\Rs ${cartProvider.discount.toStringAsFixed(2)}'),
            SizedBox(height: 8.h),
          ],
          Divider(),
          SizedBox(height: 8.h),
          _buildSummaryRow(
            'Total',
            '\Rs ${cartProvider.finalAmount.toStringAsFixed(2)}',
            isBold: true,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Handle checkout
                if (cartProvider.items.isNotEmpty) {
                  _showCheckoutDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Your cart is empty'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 60.h),
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
            fontSize: isBold ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showCheckoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Checkout'),
          content: Text(
              'This is a demo app. In a real app, this would proceed to the payment screen.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final cartProvider =
                    Provider.of<CartProvider>(context, listen: false);
                cartProvider.clear();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order placed successfully!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Place Order'),
            ),
          ],
        );
      },
    );
  }
}
