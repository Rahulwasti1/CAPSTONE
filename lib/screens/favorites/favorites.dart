import 'package:capstone/provider/favourite_provider.dart';
import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFavorites extends StatelessWidget {
  const UserFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: 'Favorites'),
            Expanded(child: _buildFavoritesContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesContent(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final List<String> favoriteProductIds =
        favoriteProvider.favoriteProductIds();

    if (favoriteProductIds.isEmpty) {
      return _buildEmptyFavorites(context);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFavoriteProducts(favoriteProductIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading your favorites'),
            );
          }

          final favoriteProducts = snapshot.data ?? [];

          if (favoriteProducts.isEmpty) {
            return _buildEmptyFavorites(context);
          }

          return GridView.builder(
            padding: EdgeInsets.all(16.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return _buildFavoriteItem(context, product, favoriteProvider);
            },
          );
        });
  }

  Future<List<Map<String, dynamic>>> _fetchFavoriteProducts(
      List<String> productIds) async {
    if (productIds.isEmpty) return [];

    List<Map<String, dynamic>> products = [];

    try {
      // Get Firestore instance
      final firestore = FirebaseFirestore.instance;

      // Fetch products from admin_products collection
      for (String productId in productIds) {
        final doc =
            await firestore.collection('admin_products').doc(productId).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;

          // Parse price for display
          String formattedPrice = 'Price not available';
          if (data['price'] != null) {
            if (data['price'] is int || data['price'] is double) {
              formattedPrice = 'Rs ${data['price'].toString()}';
            } else if (data['price'] is String) {
              formattedPrice = 'Rs ${data['price']}';
            }
          }

          // Get image URLs
          List<String> imageURLs = [];
          if (data['imageURLs'] != null && data['imageURLs'] is List) {
            imageURLs = List<String>.from(data['imageURLs']);
          }

          // Add the product to our list
          products.add({
            'id': doc.id,
            'title': data['title'] ?? 'Unknown Product',
            'price': formattedPrice,
            'numericPrice': data['price'] ?? 0,
            'imageURLs': imageURLs,
            'colors':
                data['colors'] != null ? List<String>.from(data['colors']) : [],
            'sizes':
                data['sizes'] != null ? List<String>.from(data['sizes']) : [],
          });
        }
      }
    } catch (e) {
      print('Error fetching favorite products: $e');
    }

    return products;
  }

  Widget _buildEmptyFavorites(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add products to your favorites to see them here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Navigate back to products or categories
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Explore Products',
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

  Widget _buildFavoriteItem(BuildContext context, Map<String, dynamic> product,
      FavoriteProvider favoriteProvider) {
    final String productId = product['id'] as String;
    final String productTitle =
        product['title'] as String? ?? 'Unnamed Product';
    final String productPrice =
        product['price'] as String? ?? 'Price not available';
    final List<String> imageURLs =
        (product['imageURLs'] as List<String>?) ?? [];
    final String imageUrl = imageURLs.isNotEmpty ? imageURLs.first : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
                child: Container(
                  width: double.infinity,
                  height: 120.h,
                  color: Colors.grey[200],
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 30.sp,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 30.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: _buildCircleButton(
                  icon: Icons.favorite,
                  color: Colors.red,
                  onPressed: () {
                    favoriteProvider.removeFromFavorites(productId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed from favorites'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Product details
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Text(
                  productPrice,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber[800],
                  ),
                ),
                SizedBox(height: 12.h),
                _buildAddToCartButton(context, product),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(
      BuildContext context, Map<String, dynamic> product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Get necessary information
          final String productId = product['id'] as String;
          final String productName =
              product['title'] as String? ?? 'Unnamed Product';
          final double productPrice = (product['numericPrice'] is int)
              ? (product['numericPrice'] as int).toDouble()
              : ((product['numericPrice'] is double)
                  ? (product['numericPrice'] as double)
                  : 0.0);
          final List<String> imageURLs =
              (product['imageURLs'] as List<String>?) ?? [];
          final String imageUrl = imageURLs.isNotEmpty ? imageURLs.first : '';

          // Add to cart
          cartProvider.addItem(
            productId: productId,
            title: productName,
            price: productPrice,
            imageUrl: imageUrl,
            color: '',
            size: '',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to cart'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'VIEW CART',
                onPressed: () {
                  // Navigate to cart
                  // You can implement this later
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          'Add to Cart',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
