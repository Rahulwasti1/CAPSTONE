import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomListViewBuilder {
  final List<Map<String, dynamic>> buttonData = [
    {"image": "assets/images/category_image/apparel.png", "text": "Apparel"},
    {"image": "assets/images/category_image/glass.png", "text": "Sunglasses"},
    {"image": "assets/images/category_image/watch.png", "text": "Watches"},
    {"image": "assets/images/category_image/shoes.png", "text": "Shoes"},
    {
      "icon": Icons.emoji_objects,
      "text": "Headwear"
    }, // Using icon instead of image
  ];

  Widget buildListView() {
    return Align(
      child: Transform.translate(
        offset: Offset(-3.w, 0.h),
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: buttonData.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to categories page with specific category
                        _navigateToCategory(context, buttonData[index]["text"]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFf8f3f0),
                        elevation: 0.1,
                        shape: CircleBorder(),
                        minimumSize: Size(70, 70),
                      ),
                      child: buttonData[index]["image"] != null
                          ? Image.asset(
                              buttonData[index]["image"],
                              color: CustomColors.secondaryColor,
                              width: 26.w,
                              height: 26.h,
                            )
                          : Icon(
                              buttonData[index]["icon"] ?? Icons.category,
                              color: CustomColors.secondaryColor,
                              size: 26.sp,
                            ),
                    ),
                    SizedBox(height: 5), // Space between icon & text
                    Text(
                      buttonData[index]["text"],
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Navigate to categories page with specific category selected
  void _navigateToCategory(BuildContext context, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserCategories(
          initialCategory: categoryName,
        ),
      ),
    );
  }
}
