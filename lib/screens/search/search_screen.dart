import 'package:capstone/screens/product/product_detail_screen.dart';
import 'package:capstone/widget/product_card.dart';
import 'package:capstone/service/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filterProducts();
    });
  }

  Future<void> _fetchAllProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final products = await _productService.getProducts();

      // Process products to ensure consistent format
      List<Map<String, dynamic>> processedProducts = [];
      for (var product in products) {
        // Parse price for display
        String formattedPrice = 'Price not available';
        if (product['price'] != null) {
          if (product['price'] is int || product['price'] is double) {
            formattedPrice = 'Rs ${product['price'].toString()}';
          } else if (product['price'] is String) {
            formattedPrice = 'Rs ${product['price']}';
          }
        }

        processedProducts.add({
          'id': product['id'],
          'title': product['title'] ?? 'Unknown Product',
          'description': product['description'] ?? 'No description available',
          'price': formattedPrice,
          'imageURLs': product['imageURLs'] ?? [],
          'base64Image': product['base64Image'],
          'colors': product['colors'] ?? [],
          'sizes': product['sizes'] ?? [],
          'category': product['category'] ?? 'Uncategorized',
          'genderCategory': product['genderCategory'] ?? 'Unisex',
          'rating': (4 + (product['id'].hashCode % 10) / 10),
        });
      }

      setState(() {
        allProducts = processedProducts;
        filteredProducts = processedProducts;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterProducts() {
    if (searchQuery.isEmpty) {
      filteredProducts = allProducts;
    } else {
      filteredProducts = allProducts.where((product) {
        final title = product['title'].toString().toLowerCase();
        final category = product['category'].toString().toLowerCase();
        final description = product['description'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            description.contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40.h,
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search products...",
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search results count
          if (!isLoading)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    searchQuery.isEmpty
                        ? 'All Products (${filteredProducts.length})'
                        : 'Search Results (${filteredProducts.length})',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C4024),
                    ),
                  ),
                  if (searchQuery.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'for "$searchQuery"',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Products grid
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C4024)))
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              searchQuery.isEmpty
                                  ? "No products available"
                                  : "No products found",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              searchQuery.isEmpty
                                  ? "Check back later for new products"
                                  : "Try searching with different keywords",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8.w,
                          mainAxisSpacing: 8.h,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Stack(
                            children: [
                              FlashSaleProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                        product: product,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Heart icon in top-right
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  height: 32.h,
                                  width: 32.w,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF6C4024),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10.r),
                                      bottomLeft: Radius.circular(10.r),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Handle favorite
                                    },
                                    child: Icon(
                                      Icons.favorite_border,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
