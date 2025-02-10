import 'package:another_carousel_pro/another_carousel_pro.dart';
import 'package:capstone/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  final CustomListViewBuilder listViewBuilder = CustomListViewBuilder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 22),
              child: Row(
                children: [
                  SizedBox(height: 80.h),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.brown),
                    height: 48.h,
                    width: 50.w,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 52.w),
                        child: Text(
                          " 👋 Hello!",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10.w),
                        child: Text(
                          "Rahul Wasti",
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(width: 99.w),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          print("Notification Button Clicked");
                        },
                        style: ElevatedButton.styleFrom(
                            elevation: 0.1,
                            backgroundColor: Colors.white,
                            minimumSize: Size(10.h, 40.w),
                            shape: CircleBorder()),
                        child: Icon(Icons.notifications,
                            size: 20.sp,
                            color: const Color.fromARGB(255, 31, 31, 30))),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.only(left: 19.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 317,
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
                  ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
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
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Column(
              children: [
                SizedBox(
                  height: 180.h,
                  width: 385,
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
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Category",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown)),
                      SizedBox(width: 218.w),
                      Text("See All",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown))
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Column(
                    children: [
                      listViewBuilder.buildListView(),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
