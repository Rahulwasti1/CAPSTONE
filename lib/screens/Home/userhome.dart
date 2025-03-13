import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/product/product_detail_screen.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:capstone/screens/home/home_appbar.dart';
import 'package:capstone/screens/home/home_categories.dart';
import 'package:capstone/screens/home/image_slider.dart';
import 'package:capstone/service/product_service.dart';
import 'package:capstone/widget/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchFlashSaleProducts();
  }

  Future<void> _fetchFlashSaleProducts() async {
    // Only show loading indicator if the list is empty
    if (_flashSaleProducts.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final products = await _productService.getFlashSaleProducts();
      setState(() {
        _flashSaleProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching flash sale products: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
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
                    child: TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search",
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.w, horizontal: 10.h),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
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
                      SizedBox(width: 200.w),
                      Align(
                        child: Transform.translate(
                          offset: Offset(9.w, 0.h),
                          child: TextButton(
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
                        ),
                      )
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
                              "12:30:45",
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

                  // Flash Sale Products - Vertical Layout
                  Container(
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
                                    color: Colors.grey,
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
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 15.w,
                                  mainAxisSpacing: 20.h,
                                ),
                                itemCount: _flashSaleProducts.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      ProductCard(
                                        product: _flashSaleProducts[index],
                                        onTap: () {
                                          // Navigate to product detail page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailScreen(
                                                product:
                                                    _flashSaleProducts[index],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Positioned widget for the favorite icon
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: const BoxDecoration(
                                                color:
                                                    CustomColors.secondaryColor,
                                                borderRadius: BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(20),
                                                    bottomLeft:
                                                        Radius.circular(20))),
                                            child: GestureDetector(
                                              onTap: () {
                                                // Handle the favorite button tap action here
                                              },
                                              child: Icon(
                                                Icons.favorite_border,
                                                color: Colors.white,
                                              ),
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
