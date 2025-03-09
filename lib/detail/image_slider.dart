import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductImageSlider extends StatefulWidget {
  final List<String> imageURLs;

  const ProductImageSlider({Key? key, required this.imageURLs})
      : super(key: key);

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  int currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Image Carousel - reduced height
        Container(
          height: 280.h, // Reduced height
          width: double.infinity,
          color: Colors.grey[100],
          child: widget.imageURLs.isNotEmpty
              ? PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemCount: widget.imageURLs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Image.memory(
                        base64Decode(widget.imageURLs[index]),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported,
                                    color: Colors.grey, size: 42.sp),
                                SizedBox(height: 8.h),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 42.sp),
                      SizedBox(height: 8.h),
                      Text(
                        'No images available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // Page Indicator Dots - improved style
        if (widget.imageURLs.length > 1)
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageURLs.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  height: 8.h,
                  width: currentPage == index ? 20.w : 8.w,
                  decoration: BoxDecoration(
                    color:
                        currentPage == index ? Colors.orange : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: currentPage == index
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              spreadRadius: 0.5,
                            )
                          ]
                        : [],
                  ),
                ),
              ),
            ),
          ),

        // Left and right navigation arrows
        if (widget.imageURLs.length > 1)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left arrow
                GestureDetector(
                  onTap: () {
                    if (currentPage > 0) {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40.w,
                    margin: EdgeInsets.only(left: 8.w),
                    alignment: Alignment.center,
                    child: Container(
                      height: 36.h,
                      width: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),

                // Right arrow
                GestureDetector(
                  onTap: () {
                    if (currentPage < widget.imageURLs.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 40.w,
                    margin: EdgeInsets.only(right: 8.w),
                    alignment: Alignment.center,
                    child: Container(
                      height: 36.h,
                      width: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
