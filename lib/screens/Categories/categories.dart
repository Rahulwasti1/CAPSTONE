import 'package:capstone/screens/product/product_detail_screen.dart';
import 'package:capstone/widget/product_card.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:capstone/service/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserCategories extends StatefulWidget {
  final String? initialCategory;

  const UserCategories({
    super.key,
    this.initialCategory,
  });

  @override
  State<UserCategories> createState() => _UserCategoriesState();
}

class _UserCategoriesState extends State<UserCategories> {
  final List<String> categories = [
    'All',
    'Apparel',
    'Shoes',
    'Watches',
    'Ornaments',
    'Sunglasses',
    'Headwear',
  ];

  final List<String> genderFilters = [
    'All Genders',
    'Men',
    'Women',
    'Kids',
    'Unisex',
  ];

  late String selectedCategory;
  String selectedGenderFilter = 'All Genders';
  String selectedSortOption = 'Featured';
  bool isLoading = true;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // Set initial category from widget parameter or default to 'All'
    selectedCategory = widget.initialCategory ?? 'All';
    // If the initialized category is not in the list, default to 'All'
    if (!categories.contains(selectedCategory)) {
      selectedCategory = 'All';
    }
    fetchProducts();
  }

  // Fetch products using ProductService
  Future<void> fetchProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> loadedProducts = [];

      if (selectedCategory == 'All') {
        // Get all products using ProductService
        loadedProducts = await _productService.getProducts();
        print(
            'Fetching all products - found ${loadedProducts.length} products');
      } else {
        // Check if it's a gender category
        if (['Men', 'Women', 'Kids', 'Unisex'].contains(selectedCategory)) {
          // Get all products and filter by gender
          final allProducts = await _productService.getProducts();
          loadedProducts = allProducts
              .where((product) => product['genderCategory'] == selectedCategory)
              .toList();
          print(
              'Fetching products with gender category "$selectedCategory" - found ${loadedProducts.length} products');
        } else {
          // Filter by product category using ProductService
          loadedProducts =
              await _productService.getProductsByCategory(selectedCategory);
          print(
              'Fetching products with category "$selectedCategory" - found ${loadedProducts.length} products');
        }
      }

      // Process products to ensure consistent format
      List<Map<String, dynamic>> processedProducts = [];
      for (var product in loadedProducts) {
        // Parse price for sorting later
        double parsedPrice = 0.0;
        if (product['price'] != null) {
          if (product['price'] is double) {
            parsedPrice = product['price'];
          } else if (product['price'] is int) {
            parsedPrice = (product['price'] as int).toDouble();
          } else if (product['price'] is String) {
            parsedPrice = double.tryParse(product['price']) ?? 0.0;
          }
        }

        // Prepare price for display
        String formattedPrice = 'Price not available';
        if (product['price'] != null) {
          if (product['price'] is int || product['price'] is double) {
            formattedPrice = 'Rs ${product['price'].toString()}';
          } else if (product['price'] is String) {
            formattedPrice = 'Rs ${product['price']}';
          }
        }

        // Process the product data
        processedProducts.add({
          'id': product['id'],
          'title': product['title'] ?? 'Unknown Product',
          'description': product['description'] ?? 'No description available',
          'price': formattedPrice,
          'numericPrice': parsedPrice, // Add numeric price for sorting
          'imageURLs': product['imageURLs'] ?? [],
          'base64Image': product['base64Image'],
          'colors': product['colors'] ?? [],
          'sizes': product['sizes'] ?? [],
          'category': product['category'] ?? 'Uncategorized',
          'genderCategory': product['genderCategory'] ?? 'Unisex',
          'rating': (4 +
              (product['id'].hashCode % 10) /
                  10), // Generate a random rating between 4.0 and 4.9
        });

        // Debug: Print product info
        print(
            'Product "${product['title'] ?? 'Unknown'}": category=${product['category']}, gender=${product['genderCategory']}');
      }

      if (!mounted) return;

      setState(() {
        products = processedProducts;
        applyFiltersAndSort(); // Apply initial filtering and sorting
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // Apply gender filter and sorting option
  void applyFiltersAndSort() {
    if (!mounted) return;

    // First, apply gender filter if needed
    List<Map<String, dynamic>> filtered = [];

    if (selectedGenderFilter == 'All Genders') {
      filtered = List.from(products);
    } else {
      filtered = products
          .where((product) => product['genderCategory'] == selectedGenderFilter)
          .toList();
    }

    // Then, sort the products
    switch (selectedSortOption) {
      case 'Price: Low to High':
        filtered.sort((a, b) => (a['numericPrice'] as double)
            .compareTo(b['numericPrice'] as double));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => (b['numericPrice'] as double)
            .compareTo(a['numericPrice'] as double));
        break;
      case 'Rating: High to Low':
        filtered.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'Featured': // No specific sorting, use default
      default:
        // Featured products can remain as is or implement your own logic
        break;
    }

    setState(() {
      filteredProducts = filtered;
    });
  }

  void selectCategory(String category) {
    print('Category selected: $category');
    setState(() {
      selectedCategory = category;
      // Reset gender filter when changing category
      selectedGenderFilter = 'All Genders';
    });
    fetchProducts();
  }

  void selectGenderFilter(String gender) {
    setState(() {
      selectedGenderFilter = gender;
    });
    applyFiltersAndSort();
  }

  void selectSortOption(String sortOption) {
    setState(() {
      selectedSortOption = sortOption;
    });
    applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: "Categories"),

            // Category tabs - Styled to match the image exactly
            Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final bool isSelected = selectedCategory == category;

                  return GestureDetector(
                    onTap: () => selectCategory(category),
                    child: Container(
                      margin: EdgeInsets.only(right: 10.w),
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xFF6C4024) // Brown color when selected
                            : Color(0xFFEEEEEE), // Light gray when not selected
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Filters and Sorting Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withAlpha(51), // 0.2 opacity equivalent
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Gender Filter
                  Expanded(
                    child: PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                selectedGenderFilter,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      onSelected: selectGenderFilter,
                      itemBuilder: (BuildContext context) {
                        return genderFilters.map((String gender) {
                          return PopupMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList();
                      },
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Sort Dropdown
                  Expanded(
                    child: PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 12.w),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                'Sort: $selectedSortOption',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                      onSelected: selectSortOption,
                      itemBuilder: (BuildContext context) {
                        return [
                          'Featured',
                          'Price: Low to High',
                          'Price: High to Low',
                          'Rating: High to Low'
                        ].map((String option) {
                          return PopupMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Products grid
            Expanded(
              child: isLoading
                  ? Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF6C4024)))
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No products found",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Try changing your filter or category",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                                ProductCard(
                                  product: product,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProductDetailScreen(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Heart icon in top-right
                                Positioned(
                                  top: 8.h,
                                  right: 8.w,
                                  child: Container(
                                    height: 32.h,
                                    width: 32.w,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF6C4024),
                                      borderRadius: BorderRadius.circular(16.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
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
      ),
    );
  }
}
