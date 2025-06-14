import 'dart:convert';
import 'dart:math';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/screens/camera/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import 'package:camera/camera.dart';
import 'package:capstone/screens/ar/ar_sunglasses_screen.dart';
import 'package:capstone/screens/ar/ar_ornaments_screen.dart';

import 'package:capstone/screens/ar/ar_watches_screen.dart';
import 'package:capstone/screens/ar/ar_shoes_screen.dart';
import 'package:capstone/screens/ar/ar_apparel_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, dynamic> _currentProductData = {};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Set initial product data
    _currentProductData = Map<String, dynamic>.from(widget.product);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Process product images in initState
    _processProductImages();

    // Refresh product data from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProductData();
    });
  }

  void _processProductImages() {
    // For debugging - print the product data to see all fields
    developer.log("Processing product images: ${_currentProductData['title']}");

    // Improved image handling - handle multiple scenarios
    List<String> imageURLs = [];

    // Extract all possible image sources with detailed logging
    // Case 1: 'imageURLs' field (list of strings - could be base64 or URLs)
    if (_currentProductData['imageURLs'] != null) {
      if (_currentProductData['imageURLs'] is List) {
        // When it's already a list
        imageURLs = List<String>.from(_currentProductData['imageURLs']);
        developer.log("Found imageURLs as List: ${imageURLs.length} images");
      } else if (_currentProductData['imageURLs'] is String) {
        // When it's a string with multiple images
        String imagesStr = _currentProductData['imageURLs'] as String;

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
    if (imageURLs.isEmpty && _currentProductData['images'] != null) {
      if (_currentProductData['images'] is List) {
        imageURLs = List<String>.from(_currentProductData['images']);
        developer.log("Found images as List: ${imageURLs.length} images");
      } else if (_currentProductData['images'] is String) {
        try {
          // Try to parse as JSON array if it's a stringified array
          final decoded = jsonDecode(_currentProductData['images'] as String);
          if (decoded is List) {
            imageURLs = List<String>.from(decoded);
          } else {
            imageURLs = [_currentProductData['images'] as String];
          }
        } catch (e) {
          // If not JSON, treat as single image or try delimiters
          String imagesStr = _currentProductData['images'] as String;
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

    // Case 3: Check individual fields if still no images found
    if (imageURLs.isEmpty) {
      // Check 'imageUrl' field (single image)
      if (_currentProductData['imageUrl'] != null &&
          _currentProductData['imageUrl'].toString().isNotEmpty) {
        imageURLs = [_currentProductData['imageUrl'].toString()];
        developer.log("Found single imageUrl");
      }
      // Check 'image' field (single image)
      else if (_currentProductData['image'] != null &&
          _currentProductData['image'].toString().isNotEmpty) {
        imageURLs = [_currentProductData['image'].toString()];
        developer.log("Found single image");
      }
      // Check 'downloadURL' field (common in Firebase Storage)
      else if (_currentProductData['downloadURL'] != null) {
        if (_currentProductData['downloadURL'] is List) {
          imageURLs = List<String>.from(_currentProductData['downloadURL']);
          developer.log("Found downloadURL as List");
        } else if (_currentProductData['downloadURL'] is String &&
            _currentProductData['downloadURL'].toString().isNotEmpty) {
          imageURLs = [_currentProductData['downloadURL'].toString()];
          developer.log("Found single downloadURL");
        }
      }
      // Check 'downloadUrl' field (alternate spelling)
      else if (_currentProductData['downloadUrl'] != null) {
        if (_currentProductData['downloadUrl'] is List) {
          imageURLs = List<String>.from(_currentProductData['downloadUrl']);
          developer.log("Found downloadUrl as List");
        } else if (_currentProductData['downloadUrl'] is String &&
            _currentProductData['downloadUrl'].toString().isNotEmpty) {
          imageURLs = [_currentProductData['downloadUrl'].toString()];
          developer.log("Found single downloadUrl");
        }
      }
      // Check 'imageURL' field (singular)
      else if (_currentProductData['imageURL'] != null) {
        if (_currentProductData['imageURL'] is List) {
          imageURLs = List<String>.from(_currentProductData['imageURL']);
          developer.log("Found imageURL as List");
        } else if (_currentProductData['imageURL'] is String &&
            _currentProductData['imageURL'].toString().isNotEmpty) {
          imageURLs = [_currentProductData['imageURL'].toString()];
          developer.log("Found single imageURL");
        }
      }
      // Check 'base64Image' field
      else if (_currentProductData['base64Image'] != null &&
          _currentProductData['base64Image'].toString().isNotEmpty) {
        imageURLs = [_currentProductData['base64Image'].toString()];
        developer.log("Found base64Image");
      }
    }

    // Filter out any empty strings or invalid entries
    imageURLs = imageURLs.where((url) => url.trim().isNotEmpty).toList();

    if (imageURLs.isNotEmpty) {
      developer.log("Final image count: ${imageURLs.length}");
      if (imageURLs.isNotEmpty) {
        var firstImage = imageURLs[0];
        // Don't log the full base64 string to avoid console spam
        var preview = firstImage.startsWith('http')
            ? firstImage
            : "${firstImage.substring(0, min(20, firstImage.length))}...";
        developer.log("First image sample: $preview");
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
    String category = _currentProductData['category'] as String? ?? 'Other';
    String productTitle = _currentProductData['title'] as String? ?? 'Product';

    // Debug logging
    developer.log("Product category: '$category'");
    developer.log("Product title: '$productTitle'");

    // Determine if it's a watch based on title or ID for better detection
    bool isWatch = category.toLowerCase() == 'watches' ||
        category.toLowerCase() == 'watch' ||
        productTitle.toLowerCase().contains('watch') ||
        productTitle.toLowerCase().contains('diesel') ||
        productTitle.toLowerCase().contains('guess');

    // Improved T-shirt detection
    bool isTshirt = category.toLowerCase() == 'tshirt' ||
        category.toLowerCase() == 't-shirt' ||
        category.toLowerCase() == 'apparel' ||
        productTitle.toLowerCase().contains('t-shirt') ||
        productTitle.toLowerCase().contains('tshirt') ||
        productTitle.toLowerCase().contains('shirt') ||
        productTitle.toLowerCase().contains('marvel') ||
        productTitle.toLowerCase().contains('graphic');

    // Shoes detection
    bool isShoes = category.toLowerCase() == 'shoes' ||
        category.toLowerCase() == 'footwear' ||
        category.toLowerCase() == 'sneakers' ||
        productTitle.toLowerCase().contains('shoe') ||
        productTitle.toLowerCase().contains('sneaker') ||
        productTitle.toLowerCase().contains('boot') ||
        productTitle.toLowerCase().contains('sandal') ||
        productTitle.toLowerCase().contains('heel');

    // Apparel detection (broader than just t-shirts)
    bool isApparel = category.toLowerCase() == 'apparel' ||
        category.toLowerCase() == 'clothing' ||
        category.toLowerCase() == 'dress' ||
        category.toLowerCase() == 'jacket' ||
        category.toLowerCase() == 'blazer' ||
        productTitle.toLowerCase().contains('dress') ||
        productTitle.toLowerCase().contains('jacket') ||
        productTitle.toLowerCase().contains('blazer') ||
        productTitle.toLowerCase().contains('hoodie') ||
        productTitle.toLowerCase().contains('sweater');

    // Navigate to AR screen based on category
    if (!mounted) return;

    String productImage = _imageUrls.isNotEmpty ? _imageUrls.first : '';
    String productId = _currentProductData['id'] as String? ?? '';

    developer.log("Is T-shirt: $isTshirt");
    developer.log("Is Watch: $isWatch");
    developer.log("Is Shoes: $isShoes");
    developer.log("Is Apparel: $isApparel");
    developer.log("🖼️ PRODUCT IMAGE DEBUG:");
    developer.log("   Image URLs count: ${_imageUrls.length}");
    developer.log("   Selected productImage: $productImage");
    developer.log("   Product Title: $productTitle");

    if (category.toLowerCase() == 'sunglasses') {
      // For sunglasses, use the AR sunglasses screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARSunglassesScreen(
            cameras: cameras,
            productImage: productImage,
            productTitle: productTitle,
          ),
        ),
      );
    } else if (category.toLowerCase() == 'ornaments') {
      // For ornaments, use the AR ornaments screen with product ID for specific image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AROrnamentScreen(
            cameras: cameras,
            productImage: productImage,
            productTitle: productTitle,
            productId: productId,
          ),
        ),
      );
    } else if (isTshirt) {
      // For t-shirts, use the AR apparel screen with pose detection
      developer.log(
          "Launching T-shirt AR try-on for: $productTitle (ID: $productId)");
      developer.log("Selected Color: $selectedColor");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARApparelScreen(
            productName: productTitle,
            productImage: productImage.isNotEmpty
                ? productImage
                : 'assets/images/apparel/tshirt_blue.png',
            apparelType: 'tshirt',
            selectedColor: selectedColor,
          ),
        ),
      );
    } else if (isWatch) {
      // For watches, use the AR watches screen
      developer
          .log("Launching watch AR try-on for: $productTitle (ID: $productId)");
      developer.log("Category detected: $category");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARWatchesScreen(
            cameras: cameras,
            productImage: productImage,
            productTitle: productTitle,
            productId: productId,
          ),
        ),
      );
    } else if (isShoes) {
      // For shoes, use the AR shoes screen
      developer
          .log("Launching shoes AR try-on for: $productTitle (ID: $productId)");
      developer.log("Category detected: $category");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARShoesScreen(
            productName: productTitle,
            productImage: productImage.isNotEmpty
                ? productImage
                : 'assets/images/shoes/sneaker_white.png',
          ),
        ),
      );
    } else if (isApparel && !isTshirt) {
      // For general apparel (excluding t-shirts which have their own screen)
      developer.log(
          "Launching apparel AR try-on for: $productTitle (ID: $productId)");
      developer.log("Category detected: $category");
      developer.log("Selected Color: $selectedColor");

      // Determine apparel type
      String apparelType = 'shirt'; // default
      if (productTitle.toLowerCase().contains('dress')) {
        apparelType = 'dress';
      } else if (productTitle.toLowerCase().contains('jacket') ||
          productTitle.toLowerCase().contains('blazer')) {
        apparelType = 'jacket';
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ARApparelScreen(
            productName: productTitle,
            productImage: productImage.isNotEmpty
                ? productImage
                : 'assets/images/apparel/tshirt_blue.png',
            apparelType: apparelType,
            selectedColor: selectedColor,
          ),
        ),
      );
    } else {
      // For other products, use the regular camera screen
      developer.log("Using regular camera screen for category: $category");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            cameras: cameras,
            title: productTitle,
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
    String title = _currentProductData['title'] as String? ?? "Product Name";
    String description = _currentProductData['description'] as String? ??
        "No description available.";
    String price = _currentProductData['price'] != null
        ? "Rs ${_currentProductData['price']}"
        : "Price not available";

    // Get colors from the product data
    List<String> availableColors = [];
    Map<String, String> colorCodeToName =
        {}; // Map color codes to readable names

    if (_currentProductData['colors'] != null &&
        _currentProductData['colors'] is List) {
      availableColors = List<String>.from(_currentProductData['colors']);

      // Create mapping from color codes to readable names
      for (String colorCode in availableColors) {
        colorCodeToName[colorCode] = _getColorName(colorCode);
      }
    }

    // Get sizes from the product data
    List<String> availableSizes = [];
    if (_currentProductData['sizes'] != null) {
      if (_currentProductData['sizes'] is List) {
        availableSizes = List<String>.from(_currentProductData['sizes']);
      } else if (_currentProductData['sizes'] is String) {
        availableSizes = (_currentProductData['sizes'] as String)
            .split(',')
            .map((size) => size.trim())
            .where((size) => size.isNotEmpty)
            .toList();
      }
    }

    // Handle empty values
    if (availableSizes.isEmpty) {
      availableSizes = ['L']; // Default to L instead of Free Size
    }

    if (availableColors.isEmpty) {
      availableColors = ['4278190080']; // Default black color
      colorCodeToName['4278190080'] = 'Black';
    }

    // Set initial defaults
    if (selectedSize == null && availableSizes.isNotEmpty) {
      selectedSize = availableSizes.first;
    }

    if (selectedColor == null && availableColors.isNotEmpty) {
      selectedColor = availableColors.first;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              child: RefreshIndicator(
                onRefresh: _refreshProductData,
                color: CustomColors.secondaryColor,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
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
                                            final String imageUrl =
                                                _imageUrls[index];

                                            // Check if it's a network URL
                                            if (imageUrl
                                                    .startsWith('http://') ||
                                                imageUrl
                                                    .startsWith('https://')) {
                                              return Image.network(
                                                imageUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  developer.log(
                                                      "Network image error: $error");
                                                  return _buildFallbackImage();
                                                },
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                              );
                                            }

                                            // Try to handle base64 encoded image
                                            try {
                                              // Some base64 strings might have data:image prefix
                                              String processedImageUrl =
                                                  imageUrl;
                                              if (imageUrl
                                                  .contains('base64,')) {
                                                processedImageUrl = imageUrl
                                                    .split('base64,')[1];
                                              }

                                              // Validate the base64 string and pad if needed
                                              String sanitized =
                                                  processedImageUrl.trim();
                                              int padLength =
                                                  4 - sanitized.length % 4;
                                              if (padLength < 4) {
                                                sanitized = sanitized +
                                                    ('=' * padLength);
                                              }

                                              // Now try to decode it
                                              final decodedBytes =
                                                  base64Decode(sanitized);
                                              return Image.memory(
                                                decodedBytes,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
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
                                      width:
                                          currentImageIndex == index ? 16 : 8,
                                      height: 8,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 4),
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

                            // Loading indicator overlay
                            if (_isRefreshing)
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
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
                                      children:
                                          availableColors.map((colorCode) {
                                        // Try to parse color code, with fallback
                                        Color color;
                                        try {
                                          color = Color(int.parse(colorCode
                                              .replaceAll("#", "0xFF")));
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
                                                color:
                                                    colorCode == selectedColor
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
                                        String displaySize =
                                            _getAbbreviatedSize(size);

                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedSize = size;
                                            });
                                          },
                                          child: Container(
                                            width: 60,
                                            height: 50,
                                            margin: EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Color(0xFF6B4226)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Color(0xFF6B4226)
                                                    : Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Color(0xFF6B4226)
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: Offset(0, 4),
                                                      )
                                                    ]
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      )
                                                    ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                displaySize,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
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

                          // Get readable color name instead of color code
                          String colorName = colorCodeToName[selectedColor] ??
                              _getColorName(selectedColor!);

                          cartProvider.addItem(
                            productId: _currentProductData['id'],
                            title: _currentProductData['title'],
                            price: _currentProductData['price'],
                            imageUrl:
                                _imageUrls.isNotEmpty ? _imageUrls.first : '',
                            color: colorName, // Pass readable color name
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
    String category = _currentProductData['category'] as String? ?? 'Product';

    rows.add(_buildSpecRow(
        'Brand', _currentProductData['brand'] as String? ?? 'Brand'));
    rows.add(_buildSpecRow('Type', 'Premium Product'));
    rows.add(_buildSpecRow('Category', category));

    // Add more specs if available in the product data
    if (_currentProductData['material'] != null) {
      rows.add(_buildSpecRow('Material', _currentProductData['material']));
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

  // New method to refresh product data from Firestore
  Future<void> _refreshProductData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get the product ID
      final String productId = _currentProductData['id'] ?? '';

      if (productId.isNotEmpty) {
        developer.log("Refreshing product data for ID: $productId");

        // Fetch latest data from Firestore
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('admin_products')
            .doc(productId)
            .get();

        if (doc.exists) {
          final Map<String, dynamic> refreshedData = {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id
          };

          setState(() {
            _currentProductData = refreshedData;
            _isRefreshing = false;
          });

          // Re-process images with updated data
          _processProductImages();

          developer.log("Product data refreshed successfully");
        } else {
          developer.log("Product document no longer exists");
          setState(() {
            _isRefreshing = false;
          });
        }
      } else {
        developer.log("Cannot refresh - no product ID available");
        setState(() {
          _isRefreshing = false;
        });
      }
    } catch (e) {
      developer.log("Error refreshing product data: $e");
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // Helper method to get abbreviated size labels
  String _getAbbreviatedSize(String size) {
    final abbreviations = {
      'Small': 'S',
      'Medium': 'M',
      'Large': 'L',
      'Extra Large': 'XL',
      'XXL': 'XXL',
      'Free Size': 'F',
      'One Size': 'OS',
    };

    return abbreviations[size] ?? size;
  }

  String _getColorName(String colorCode) {
    // Map common Flutter color codes to readable names
    final Map<String, String> colorMap = {
      '4278190080': 'Black',
      '4294967295': 'White',
      '4294198070': 'Blue',
      '4280391411': 'Blue',
      '4294901760': 'Red',
      '4278255360': 'Green',
      '4294934352': 'Yellow',
      '4294902015': 'Pink',
      '4289797371': 'Purple',
      '4294945600': 'Orange',
      '4286611584': 'Brown',
      '4288585374': 'Grey',
      '4278255615': 'Cyan',
      '4294902015': 'Magenta',
    };

    return colorMap[colorCode] ?? 'Color';
  }
}
