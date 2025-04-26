import 'dart:convert';
import 'dart:math';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/screens/camera/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:capstone/screens/ar/ar_sunglasses_screen.dart';

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
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Process product images in initState
    _processProductImages();
  }

  void _processProductImages() {
    // For debugging - print the product data to see all fields
    developer.log("Processing product images: ${widget.product['title']}");

    // Improved image handling - handle multiple scenarios
    List<String> imageURLs = [];

    // Case 1: 'imageURLs' field (list of base64 strings)
    if (widget.product['imageURLs'] != null) {
      if (widget.product['imageURLs'] is List) {
        // When it's already a list
        imageURLs = List<String>.from(widget.product['imageURLs']);
        developer.log("Found imageURLs as List: ${imageURLs.length} images");
      } else if (widget.product['imageURLs'] is String) {
        // When it's a string with multiple base64 images
        String imagesStr = widget.product['imageURLs'] as String;

        // Try common delimiters
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
          // If no delimiter is found, treat as single image
          imageURLs = [imagesStr];
        }
        developer.log(
            "Found imageURLs as String, parsed: ${imageURLs.length} images");
      }
    }
    // Case 2: Check 'images' field
    else if (widget.product['images'] != null) {
      if (widget.product['images'] is List) {
        imageURLs = List<String>.from(widget.product['images']);
        developer.log("Found images as List: ${imageURLs.length} images");
      } else if (widget.product['images'] is String) {
        try {
          // Try to parse as JSON array if it's a stringified array
          final decoded = jsonDecode(widget.product['images'] as String);
          if (decoded is List) {
            imageURLs = List<String>.from(decoded);
          } else {
            imageURLs = [widget.product['images'] as String];
          }
        } catch (e) {
          // If not JSON, treat as single image or try delimiters
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
        developer
            .log("Found images as String, parsed: ${imageURLs.length} images");
      }
    }
    // Case 3: Check 'imageUrl' field (single image)
    else if (widget.product['imageUrl'] != null &&
        widget.product['imageUrl'].toString().isNotEmpty) {
      imageURLs = [widget.product['imageUrl'].toString()];
      developer.log("Found single imageUrl");
    }
    // Case 4: Check 'image' field (single image)
    else if (widget.product['image'] != null &&
        widget.product['image'].toString().isNotEmpty) {
      imageURLs = [widget.product['image'].toString()];
      developer.log("Found single image");
    }

    // Filter out any empty strings or invalid entries
    imageURLs = imageURLs.where((url) => url.trim().isNotEmpty).toList();

    if (imageURLs.isNotEmpty) {
      developer.log("Final image count: ${imageURLs.length}");
      if (imageURLs.isNotEmpty) {
        developer.log(
            "First image sample: ${imageURLs[0].substring(0, min(20, imageURLs[0].length))}...");
      }
    } else {
      developer.log("No images found for this product");
    }

    setState(() {
      _imageUrls = imageURLs;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Navigate directly to camera screen instead of rechecking permissions
  Future<void> _startTryOn() async {
    // Get available cameras
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No cameras available on this device')),
      );
      return;
    }

    // Get the product category
    String category = widget.product['category'] as String? ?? 'Other';

    // Navigate to AR Sunglasses Screen for Sunglasses category, otherwise to regular camera
    if (!mounted) return;

    if (category.toLowerCase() == 'sunglasses') {
      // For sunglasses, use the AR sunglasses screen
      String productImage = _imageUrls.isNotEmpty ? _imageUrls.first : '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARSunglassesScreen(
            cameras: cameras,
            productImage: productImage,
            productTitle: widget.product['title'] as String? ?? 'Sunglasses',
          ),
        ),
      );
    } else {
      // For other products, use the regular camera screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cameras: cameras,
            title: widget.product['title'] ?? 'Product',
            category: category,
          ),
        ),
      );
    }
  }

  // Fallback image widget
  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Image not available",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract product details
    String title = widget.product['title'] as String? ?? "Product Name";
    String description =
        widget.product['description'] as String? ?? "No description available.";
    String price = widget.product['price'] != null
        ? "Rs ${widget.product['price']}"
        : "Price not available";

    // Get colors from the product data
    List<String> availableColors = [];
    if (widget.product['colors'] != null && widget.product['colors'] is List) {
      availableColors = List<String>.from(widget.product['colors']);
    }

    // Get sizes from the product data
    List<String> availableSizes = [];
    if (widget.product['sizes'] != null) {
      if (widget.product['sizes'] is List) {
        availableSizes = List<String>.from(widget.product['sizes']);
      } else if (widget.product['sizes'] is String) {
        availableSizes = (widget.product['sizes'] as String)
            .split(',')
            .map((size) => size.trim())
            .where((size) => size.isNotEmpty)
            .toList();
      }
    }

    // Handle empty values
    if (availableSizes.isEmpty) {
      availableSizes = ['Free Size'];
    }

    if (availableColors.isEmpty) {
      availableColors = ['Default'];
    }

    // Set initial defaults
    if (selectedSize == null && availableSizes.isNotEmpty) {
      selectedSize = availableSizes.first;
    }

    if (selectedColor == null && availableColors.isNotEmpty) {
      selectedColor = availableColors.first;
    }

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
                            itemCount:
                                _imageUrls.isEmpty ? 1 : _imageUrls.length,
                            onPageChanged: (index) {
                              setState(() {
                                currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.all(20),
                                child: _imageUrls.isNotEmpty
                                    ? Builder(
                                        builder: (context) {
                                          try {
                                            // Attempt to decode and display the image
                                            return Image.memory(
                                              base64Decode(_imageUrls[index]),
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                developer.log(
                                                    "Image decode error: $error");
                                                return _buildFallbackImage();
                                              },
                                            );
                                          } catch (e) {
                                            // Handle any base64 decoding exceptions
                                            developer
                                                .log("Image exception: $e");
                                            return _buildFallbackImage();
                                          }
                                        },
                                      )
                                    : _buildFallbackImage(),
                              );
                            },
                          ),

                          // Image navigation dots
                          if (_imageUrls.length > 1)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _imageUrls.length,
                                  (index) => Container(
                                    width: currentImageIndex == index ? 16 : 8,
                                    height: 8,
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: currentImageIndex == index
                                          ? CustomColors.secondaryColor
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
                              fontSize: 30,
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
                          availableColors.isEmpty
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .brown, // Default brown if no colors
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: availableColors.map((colorCode) {
                                      // Try to parse color code, with fallback
                                      Color color;
                                      try {
                                        color = Color(int.parse(
                                            colorCode.replaceAll("#", "0xFF")));
                                      } catch (e) {
                                        // Default to a brown color if parse fails
                                        color = Colors.brown;
                                      }

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
                                            color: color,
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
                          availableSizes.isEmpty
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
                                    children: availableSizes.map((size) {
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
                                      ? CustomColors.secondaryColor
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
                                      ? CustomColors.secondaryColor
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
                              children: _buildSpecRows(
                                  availableSizes, availableColors),
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
                      border: Border.all(color: CustomColors.secondaryColor),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextButton.icon(
                      icon: Icon(Icons.camera_alt,
                          color: CustomColors.secondaryColor),
                      label: Text(
                        "Try On",
                        style: TextStyle(
                          color: CustomColors.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: _startTryOn,
                    ),
                  ),

                  // Add to Cart button
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: CustomColors.secondaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (selectedColor == null || selectedSize == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select color and size'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          final cartProvider =
                              Provider.of<CartProvider>(context, listen: false);
                          cartProvider.addItem(
                            productId: widget.product['id'],
                            title: widget.product['title'],
                            price: widget.product['price'],
                            imageUrl:
                                _imageUrls.isNotEmpty ? _imageUrls.first : '',
                            color: selectedColor!,
                            size: selectedSize!,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              duration: Duration(seconds: 2),
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

  List<Widget> _buildSpecRows(List<String> sizes, List<String> colors) {
    List<Widget> rows = [];

    // Use product category if available
    String category = widget.product['category'] as String? ?? 'Product';

    rows.add(
        _buildSpecRow('Brand', widget.product['brand'] as String? ?? 'Brand'));
    rows.add(_buildSpecRow('Type', 'Premium Product'));
    rows.add(_buildSpecRow('Category', category));

    // Add more specs if available in the product data
    if (widget.product['material'] != null) {
      rows.add(_buildSpecRow('Material', widget.product['material']));
    } else {
      rows.add(_buildSpecRow('Material', 'Premium Material'));
    }

    rows.add(_buildSpecRow('Available Sizes', sizes.join(', ')));
    rows.add(_buildSpecRow('Available Colors', colors.length.toString()));

    return rows;
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
