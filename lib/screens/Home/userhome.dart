import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/Categories/categories.dart';
import 'package:capstone/screens/Home/homeAppBar.dart';
import 'package:capstone/screens/Home/home_categories.dart';
import 'package:capstone/screens/Home/image_slider.dart';
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
            child: Column(children: [
          SizedBox(height: 10.h),
          Homeappbar(), // Home App Bar
          SizedBox(height: 17.h),
          // App Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                SizedBox(
                  width: 305,
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

          // Category Sectoin

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
                Row(
                  children: [
                    Text(
                      "Flash Sale",
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: CustomColors.secondaryColor),
                    ),
                    SizedBox(width: 100),
                    Text(
                      "Closing in:",
                      style: TextStyle(color: CustomColors.secondaryColor),
                    )
                  ],
                )
              ],
            ),
          )
        ])));
  }
}
