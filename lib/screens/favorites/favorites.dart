import 'package:capstone/provider/favourite_provider.dart';
import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:capstone/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFavorites extends StatelessWidget {
  const UserFavorites({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                UserAppbar(text: 'Favorites'),
                Expanded(child: _buildFavoritesContent(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesContent(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final theme = Theme.of(context);
    final List<String> favoriteProductIds =
        favoriteProvider.favoriteProductIds();

    if (favoriteProductIds.isEmpty) {
      return _buildEmptyFavorites(context);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFavoriteProducts(favoriteProductIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.brown,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading your favorites',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
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
              Icons.favorite_border,
              size: 64.sp,
              color: theme.iconTheme.color?.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.headlineSmall?.color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add products to your favorites to see them here',
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
                // Navigate back to products or categories
                Navigator.of(context).pop();
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
                'Explore Products',
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

  Widget _buildFavoriteItem(BuildContext context, Map<String, dynamic> product,
      FavoriteProvider favoriteProvider) {
    final theme = Theme.of(context);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
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
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 32.sp,
                                    color:
                                        theme.iconTheme.color?.withOpacity(0.5),
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
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
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.brown,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
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
                              child: Icon(
                                Icons.image_outlined,
                                size: 32.sp,
                                color: theme.iconTheme.color?.withOpacity(0.5),
                              ),
                            ),
                          ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20.sp,
                        ),
                        onPressed: () {
                          favoriteProvider.toggleFavorite(productId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Removed from favorites',
                                style: TextStyle(color: Colors.white),
                              ),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor:
                                  theme.brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[700],
                            ),
                          );
                        },
                        padding: EdgeInsets.all(4.r),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productTitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        productPrice,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                  // Add to Cart button
                  Container(
                    width: double.infinity,
                    height: 32.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.brown.shade600, Colors.brown.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final cartProvider =
                            Provider.of<CartProvider>(context, listen: false);

                        // Get colors and sizes
                        final List<String> colors = product['colors'] ?? [];
                        final List<String> sizes = product['sizes'] ?? [];

                        cartProvider.addItem(
                          productId: productId,
                          title: productTitle,
                          price: product['numericPrice']?.toDouble() ?? 0.0,
                          imageUrl: imageUrl,
                          color: colors.isNotEmpty ? colors.first : '',
                          size: sizes.isNotEmpty ? sizes.first : '',
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added to cart',
                              style: TextStyle(color: Colors.white),
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
