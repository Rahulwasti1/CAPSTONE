import 'package:capstone/constants/colors.dart';
import 'package:capstone/detail/image_slider.dart';
import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/provider/favourite_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  int selectedColorIndex = 0;
  String selectedSize = '';
  int quantity = 1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with first size from product data
    if (widget.product['sizes'] != null &&
        widget.product['sizes'].toString().isNotEmpty) {
      selectedSize = widget.product['sizes'].toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void changeSelectedColor(int index) {
    setState(() {
      selectedColorIndex = index;
    });
  }

  void setSelectedSize(String size) {
    setState(() {
      selectedSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract product data
    String title = widget.product['title'] ?? 'Unknown Product';
    var priceValue = widget.product['price'];
    String price = 'Price not available';
    if (priceValue != null) {
      if (priceValue is int || priceValue is double) {
        price = '\$${priceValue.toString()}';
      } else if (priceValue is String) {
        price = '\$$priceValue';
      }
    }

    // Handle colors
    List<String> colors = [];
    if (widget.product['colors'] != null && widget.product['colors'] is List) {
      colors = List<String>.from(widget.product['colors']);
    }

    // Handle sizes - Get from product data
    List<String> sizeOptions = [];
    if (widget.product['sizes'] != null) {
      if (widget.product['sizes'] is String) {
        sizeOptions = [widget.product['sizes'].toString()];
      } else if (widget.product['sizes'] is List) {
        sizeOptions = List<String>.from(widget.product['sizes']);
      }
    }

    // Set default size if none selected
    if (selectedSize.isEmpty && sizeOptions.isNotEmpty) {
      selectedSize = sizeOptions[0];
    }

    // Handle images
    List<String> imageURLs = [];
    if (widget.product['imageURLs'] != null &&
        widget.product['imageURLs'] is List) {
      imageURLs = List<String>.from(widget.product['imageURLs']);
    }

    // Get product ID for favorites
    String productId = widget.product['id'] ?? DateTime.now().toString();

    // Access providers
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    // Check if product is favorite
    bool isFavorite = favoriteProvider.isFavorite(productId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.share,
                color: Colors.black87,
                size: 22.sp,
              ),
              onPressed: () {
                // Share functionality
              },
            ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black87,
                size: 22.sp,
              ),
              onPressed: () {
                favoriteProvider.toggleFavorite(productId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    margin: EdgeInsets.all(10),
                  ),
                );
              },
            ),
            SizedBox(width: 8.w),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            ProductImageSlider(imageURLs: imageURLs),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Product Price
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Color Selection
                  if (colors.isNotEmpty) ...[
                    Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          colors.length,
                          (index) => GestureDetector(
                            onTap: () => changeSelectedColor(index),
                            child: Container(
                              margin: EdgeInsets.only(right: 15.w),
                              height: 40.h,
                              width: 40.w,
                              decoration: BoxDecoration(
                                color: Color(int.parse(colors[index])),
                                shape: BoxShape.circle,
                                border: selectedColorIndex == index
                                    ? Border.all(color: Colors.black, width: 2)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Size Selection - Using product's actual sizes
                  if (sizeOptions.isNotEmpty) ...[
                    Text(
                      'Size',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: sizeOptions
                            .map((size) => GestureDetector(
                                  onTap: () => setSelectedSize(size),
                                  child: Container(
                                    width: 50.w,
                                    height: 50.h,
                                    margin: EdgeInsets.only(right: 12.w),
                                    decoration: BoxDecoration(
                                      color: selectedSize == size
                                          ? Colors.black
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: selectedSize == size
                                            ? Colors.black
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: selectedSize == size
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Description & Specifications Tab Bar - Matched to reference image
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.r),
                        color: Colors.orange,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black87,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                      tabs: [
                        Tab(text: 'Description'),
                        Tab(text: 'Specifications'),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Tab content
                  Container(
                    height: 120.h,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Description Tab
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 8.h, horizontal: 4.w),
                          child: Text(
                            widget.product['description'] ??
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[800],
                              height: 1.6,
                            ),
                          ),
                        ),

                        // Specifications Tab
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 8.h, horizontal: 4.w),
                          child: Text(
                            'Product specifications not available',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[800],
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 50.h), // Space for floating action bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Try On Button
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Try On feature coming soon!'),
                      backgroundColor: Colors.white,
                    ),
                  );
                },
                icon: Icon(Icons.camera_alt_outlined, size: 18.sp),
                label: Text(
                  'Try On',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.secondaryColor
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Add to Cart Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  // Add to cart functionality
                  if (colors.isNotEmpty) {
                    cartProvider.addItem(
                      productId: productId,
                      title: title,
                      price: priceValue is double
                          ? priceValue
                          : double.tryParse(priceValue.toString()) ?? 0.0,
                      quantity: 1,
                      imageUrl: imageURLs.isNotEmpty ? imageURLs[0] : '',
                      color: colors[selectedColorIndex],
                      size: selectedSize,
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to cart!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
