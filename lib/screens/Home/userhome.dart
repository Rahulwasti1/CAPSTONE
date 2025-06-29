import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/product/product_detail_screen.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:capstone/screens/home/home_appbar.dart';
import 'package:capstone/screens/home/home_categories.dart';
import 'package:capstone/screens/home/image_slider.dart';
import 'package:capstone/screens/search/search_screen.dart';
import 'package:capstone/service/product_service.dart';
import 'package:capstone/widget/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  final CustomListViewBuilder listViewBuilder = CustomListViewBuilder();
  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> _flashSaleProducts = [];
  bool _isLoading = true;

  // Static flash sale time display (no longer counting down)
  final String _currentTimeString = "12:30:45"; // Fixed display time

  @override
  void initState() {
    super.initState();
    _fetchFlashSaleProducts();
  }

  Future<void> _fetchFlashSaleProducts() async {
    if (!mounted) return;

    // Only show loading indicator if the list is empty
    if (_flashSaleProducts.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final products = await _productService.getFlashSaleProducts();

      if (!mounted) return;

      setState(() {
        _flashSaleProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      developer.log("Error fetching flash sale products: $e");
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleProductTap(Map<String, dynamic> product) {
    // Simply navigate to product details - no popup
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(children: [
            SizedBox(height: 10.h),
            Homeappbar(), // Home App Bar
            SizedBox(height: 17.h),
            // App Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 330,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search,
                                color: Theme.of(context).iconTheme.color),
                            hintText: "Search",
                            hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10.w, horizontal: 10.h),
                            border: InputBorder.none,
                            disabledBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(50.w, 43.h),
                            padding: EdgeInsets.zero),
                        child: SizedBox(
                          child: Icon(
                            Icons.tune,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        )),
                  ),
                ],
              ),
            ),
            SizedBox(height: 19.h),
            // Image Slider Section
            ImageSlider(),

            SizedBox(height: 10.h),

            // Category Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Category",
                          style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: CustomColors.secondaryColor)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserCategories()));
                        },
                        child: Text("See All",
                            style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: CustomColors.secondaryColor)),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Column(
                    children: [
                      listViewBuilder.buildListView(),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // Flash Sale Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Flash Sale",
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: CustomColors.secondaryColor),
                      ),
                      Row(
                        children: [
                          Text(
                            "Closing in:",
                            style: TextStyle(
                              color: CustomColors.secondaryColor,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: CustomColors.secondaryColor,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              _currentTimeString,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),

                  // Flash Sale Products - Vertical Grid Layout
                  SizedBox(
                    width: double.infinity,
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: CustomColors.secondaryColor,
                            ),
                          )
                        : _flashSaleProducts.isEmpty
                            ? Center(
                                child: Text(
                                  "No flash sale products available",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 8.w,
                                  mainAxisSpacing: 8.h,
                                ),
                                itemCount: _flashSaleProducts.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      FlashSaleProductCard(
                                        product: _flashSaleProducts[index],
                                        onTap: () => _handleProductTap(
                                            _flashSaleProducts[index]),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          height: 32.h,
                                          width: 32.w,
                                          decoration: BoxDecoration(
                                            color: CustomColors.secondaryColor,
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

                  SizedBox(height: 20.h),
                ],
              ),
            )
          ]),
        )));
  }
}
