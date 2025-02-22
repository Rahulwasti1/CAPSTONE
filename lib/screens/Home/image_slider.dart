import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ImageSlider extends StatefulWidget {
  const ImageSlider({super.key});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.h,
      width: 345.w,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnotherCarousel(
          images: [
            AssetImage("assets/images/banner_images/1.png"),
            AssetImage("assets/images/banner_images/2.png"),
            AssetImage("assets/images/banner_images/3.png"),
            AssetImage("assets/images/banner_images/4.png"),
            AssetImage("assets/images/banner_images/5.png"),
          ],
          dotSize: 2,
          indicatorBgPadding: 1.5,
        ),
      ),
    );
  }
}
