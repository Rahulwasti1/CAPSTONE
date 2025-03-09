import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  int quantity = 1;
  int currentImageIndex = 0;
  String? selectedSize;
  bool isLiked = false;
  final PageController _pageController = PageController();
  late TabController _tabController;
  String? selectedColor;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract product details
    String title =
        widget.product['title'] as String? ?? "Caliber Shoes Coffee Sneakers";
    String description = widget.product['description'] as String? ??
        "Sail smoothly from work to party, with our stylishly comfy CONOR 567SK which is a classic example for effortless fashion. Made out of the oil-pull microfiber material with a stroke of suede on the upper part and a cushioned cloth lining that provides a comfortable fit all day long.";
    String price = widget.product['price'] != null
        ? "Rs ${widget.product['price']}"
        : "Rs 1710.0";

    // For debugging - print the product data to see all fields
    print("Product data: ${widget.product}");

    // Improved image handling - handle multiple scenarios
    List<String> imageURLs = [];

    // Case 1: Standard list of images
    if (widget.product['imageURLs'] != null &&
        widget.product['imageURLs'] is List) {
      imageURLs = List<String>.from(widget.product['imageURLs']);
    }
    // Case 2: Single string with images separated by delimiters
    else if (widget.product['imageURLs'] != null &&
        widget.product['imageURLs'] is String) {
      String imagesStr = widget.product['imageURLs'] as String;

      // Try common delimiters - semicolon, comma, pipe
      if (imagesStr.contains(';')) {
        imageURLs =
            imagesStr.split(';').where((img) => img.trim().isNotEmpty).toList();
      } else if (imagesStr.contains(',')) {
        imageURLs =
            imagesStr.split(',').where((img) => img.trim().isNotEmpty).toList();
      } else if (imagesStr.contains('|')) {
        imageURLs =
            imagesStr.split('|').where((img) => img.trim().isNotEmpty).toList();
      } else {
        // If no delimiter is found but it's a valid base64 string, treat as single image
        imageURLs = [imagesStr];
      }
    }
    // Case 3: Try other possible field names
    else if (widget.product['images'] != null) {
      if (widget.product['images'] is List) {
        imageURLs = List<String>.from(widget.product['images']);
      } else if (widget.product['images'] is String) {
        String imagesStr = widget.product['images'] as String;
        if (imagesStr.contains(';')) {
          imageURLs = imagesStr
              .split(';')
              .where((img) => img.trim().isNotEmpty)
              .toList();
        } else if (imagesStr.contains(',')) {
          imageURLs = imagesStr
              .split(',')
              .where((img) => img.trim().isNotEmpty)
              .toList();
        } else if (imagesStr.contains('|')) {
          imageURLs = imagesStr
              .split('|')
              .where((img) => img.trim().isNotEmpty)
              .toList();
        } else {
          imageURLs = [imagesStr];
        }
      }
    }

    // Debugging image processing
    print("Found ${imageURLs.length} images");
    if (imageURLs.isNotEmpty) {
      print(
          "First image begins with: ${imageURLs[0].substring(0, min(20, imageURLs[0].length))}...");
    }

    // Get colors from the product data
    List<String> colors = [];
    if (widget.product['colors'] != null && widget.product['colors'] is List) {
      colors = List<String>.from(widget.product['colors']);
      // Select the first color by default if none is selected
      if (selectedColor == null && colors.isNotEmpty) {
        selectedColor = colors[0];
      }
    }

    // Get sizes from the product data - check multiple possible field names
    List<String> sizes = [];
    // Check various possible field names that might be in your Firestore
    if (widget.product['sizes'] != null && widget.product['sizes'] is List) {
      sizes = List<String>.from(widget.product['sizes']);
    } else if (widget.product['size'] != null &&
        widget.product['size'] is List) {
      sizes = List<String>.from(widget.product['size']);
    } else if (widget.product['availableSizes'] != null &&
        widget.product['availableSizes'] is List) {
      sizes = List<String>.from(widget.product['availableSizes']);
    } else if (widget.product['available_sizes'] != null &&
        widget.product['available_sizes'] is List) {
      sizes = List<String>.from(widget.product['available_sizes']);
    }

    // If it might be stored as a string with comma separation
    else if (widget.product['sizes'] is String) {
      sizes = (widget.product['sizes'] as String)
          .split(',')
          .map((size) => size.trim())
          .toList();
    } else if (widget.product['size'] is String) {
      sizes = (widget.product['size'] as String)
          .split(',')
          .map((size) => size.trim())
          .toList();
    }

    // Select first size by default
    if (selectedSize == null && sizes.isNotEmpty) {
      selectedSize = sizes[0];
    }

    // Join sizes for display in specifications
    String availableSizesText =
        sizes.isEmpty ? "Not specified" : sizes.join(", ");

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation with back button, share and like icons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.share_outlined, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: isLiked ? Colors.red : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            isLiked = !isLiked;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image carousel
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                      ),
                      child: Stack(
                        children: [
                          // Image carousel
                          PageView.builder(
                            controller: _pageController,
                            itemCount: imageURLs.isEmpty ? 1 : imageURLs.length,
                            onPageChanged: (index) {
                              setState(() {
                                currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.all(20),
                                child: imageURLs.isNotEmpty
                                    ? Image.memory(
                                        base64Decode(imageURLs[index]),
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.network(
                                            'https://www.transparentpng.com/thumb/sneakers/sneakers-shoes-clipart-png-image-3.png',
                                            fit: BoxFit.contain,
                                          );
                                        },
                                      )
                                    : Image.network(
                                        'https://www.transparentpng.com/thumb/sneakers/sneakers-shoes-clipart-png-image-3.png',
                                        fit: BoxFit.contain,
                                      ),
                              );
                            },
                          ),

                          // Image navigation dots
                          if (imageURLs.length > 1)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  imageURLs.length,
                                  (index) => Container(
                                    width: currentImageIndex == index ? 16 : 8,
                                    height: 8,
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: currentImageIndex == index
                                          ? Color(0xFFF9A826)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Product title and price
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Color section
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Color",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          colors.isEmpty
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(
                                        0xFF6C4024), // Default brown if no colors
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: colors.map((colorCode) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedColor = colorCode;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          margin: EdgeInsets.only(right: 15),
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(colorCode)),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: colorCode == selectedColor
                                                  ? Colors.black
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // Size section
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Size",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          sizes.isEmpty
                              ? Container(
                                  // Show a single default size if no sizes available
                                  width: 60,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "9",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: sizes.map((size) {
                                      bool isSelected = selectedSize == size;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedSize = size;
                                          });
                                        },
                                        child: Container(
                                          width: 60,
                                          height: 50,
                                          margin: EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              size,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // Tab section - matching the provided image
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(4),
                      child: Row(
                        children: [
                          // Description tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _tabController.animateTo(0);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0
                                      ? Color(0xFFF9A826) // Orange active color
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    "Description",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTabIndex == 0
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Specifications tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _tabController.animateTo(1);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1
                                      ? Color(0xFFF9A826) // Orange active color
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Center(
                                  child: Text(
                                    "Specifications",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTabIndex == 1
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab content
                    Container(
                      height: 200,
                      padding: EdgeInsets.all(20),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Description tab content with justified text
                          SingleChildScrollView(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),

                          // Specifications tab content
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSpecRow(
                                    "Brand",
                                    widget.product['brand'] as String? ??
                                        "Caliber"),
                                _buildSpecRow(
                                    "Type",
                                    widget.product['type'] as String? ??
                                        "Coffee Sneakers"),
                                _buildSpecRow(
                                    "Available Sizes", availableSizesText),
                                _buildSpecRow(
                                    "Material",
                                    widget.product['material'] as String? ??
                                        "Premium Leather"),
                                _buildSpecRow(
                                    "Inner Lining",
                                    widget.product['innerLining'] as String? ??
                                        "Cushioned cloth"),
                                _buildSpecRow(
                                    "Origin",
                                    widget.product['origin'] as String? ??
                                        "Made in Italy"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom bar with buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Try On button
                  Container(
                    width: 110,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextButton.icon(
                      icon:
                          Icon(Icons.camera_alt, color: Colors.lightBlueAccent),
                      label: Text(
                        "Try On",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        // Try on functionality
                      },
                    ),
                  ),

                  // Add to Cart button
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFF9A826), // Orange color
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to cart'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
