import 'package:capstone/screens/product/product_detail_screen.dart';
import 'package:capstone/widget/product_card.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Fetch products from Firestore
  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot;

      if (selectedCategory == 'All') {
        // Get all products
        snapshot =
            await FirebaseFirestore.instance.collection('admin_products').get();
        print('Fetching all products - found ${snapshot.docs.length} products');
      } else {
        // Check if it's a gender category
        if (['Men', 'Women', 'Kids', 'Unisex'].contains(selectedCategory)) {
          // Filter by gender category
          snapshot = await FirebaseFirestore.instance
              .collection('admin_products')
              .where('genderCategory', isEqualTo: selectedCategory)
              .get();
          print(
              'Fetching products with gender category "$selectedCategory" - found ${snapshot.docs.length} products');
        } else {
          // Filter by product category - using the exact database category name
          snapshot = await FirebaseFirestore.instance
              .collection('admin_products')
              .where('category', isEqualTo: selectedCategory)
              .get();
          print(
              'Fetching products with category "$selectedCategory" - found ${snapshot.docs.length} products');
        }
      }

      List<Map<String, dynamic>> loadedProducts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Log the category of each product to help with debugging
        print(
            'Product "${data['title'] ?? 'Unknown'}": category=${data['category']}, gender=${data['genderCategory']}');

        // Parse price for sorting later
        double parsedPrice = 0.0;
        if (data['price'] != null) {
          if (data['price'] is double) {
            parsedPrice = data['price'];
          } else if (data['price'] is int) {
            parsedPrice = (data['price'] as int).toDouble();
          } else if (data['price'] is String) {
            parsedPrice = double.tryParse(data['price']) ?? 0.0;
          }
        }

        // Prepare price for display
        String formattedPrice = 'Price not available';
        if (data['price'] != null) {
          if (data['price'] is int || data['price'] is double) {
            formattedPrice = 'Rs ${data['price'].toString()}';
          } else if (data['price'] is String) {
            formattedPrice = 'Rs ${data['price']}';
          }
        }

        // Get all images
        List<String> imageURLs = [];
        if (data['imageURLs'] != null && data['imageURLs'] is List) {
          imageURLs = List<String>.from(data['imageURLs']);
        }
        String? base64Image = imageURLs.isNotEmpty ? imageURLs[0] : null;

        // Convert Firestore document to a map for the product card
        loadedProducts.add({
          'id': doc.id,
          'title': data['title'] ?? 'Unknown Product',
          'description': data['description'] ?? 'No description available',
          'price': formattedPrice,
          'numericPrice': parsedPrice, // Add numeric price for sorting
          'imageURLs': imageURLs,
          'base64Image': base64Image,
          'colors':
              data['colors'] != null ? List<String>.from(data['colors']) : [],
          'sizes':
              data['sizes'] != null ? List<String>.from(data['sizes']) : [],
          'category': data['category'] ?? 'Uncategorized',
          'genderCategory': data['genderCategory'] ?? 'Unisex',
          'rating': (4 +
              (doc.id.hashCode % 10) /
                  10), // Generate a random rating between 4.0 and 4.9
        });
      }

      setState(() {
        products = loadedProducts;
        applyFiltersAndSort(); // Apply initial filtering and sorting
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Apply gender filter and sorting option
  void applyFiltersAndSort() {
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
      backgroundColor: Colors.white,
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
                            Text(
                              selectedGenderFilter,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
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
                            Text(
                              'Sort: $selectedSortOption',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Spacer(),
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
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 10.w,
                            mainAxisSpacing: 10.h,
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
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF6C4024),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.favorite_border,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                // Rating at bottom
                                Positioned(
                                  bottom: 8,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Color(0xFF6C4024),
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "${product['rating'].toStringAsFixed(1)}",
                                          style: TextStyle(
                                            color: Color(0xFF6C4024),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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
