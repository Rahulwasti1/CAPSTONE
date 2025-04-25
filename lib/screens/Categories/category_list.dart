import 'package:capstone/screens/categories/categories.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Main product categories (using exact database names)
    final List<String> productCategories = [
      'Apparel',
      'Shoes',
      'Watches',
      'Ornaments',
      'Sunglasses',
    ];

    // Gender categories
    final List<String> genderCategories = [
      'Men',
      'Women',
      'Kids',
      'Unisex',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: "All Categories"),
            Expanded(
              child: ListView(
                children: [
                  // Product Categories Section
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                    child: Text(
                      "Product Categories",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C4024),
                      ),
                    ),
                  ),
                  ...productCategories
                      .map((category) =>
                          _buildCategoryItem(context, category, false))
                      .toList(),

                  SizedBox(height: 16.h),

                  // Gender Categories Section
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
                    child: Text(
                      "Shop by Gender",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C4024),
                      ),
                    ),
                  ),
                  ...genderCategories
                      .map((category) =>
                          _buildCategoryItem(context, category, true))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      BuildContext context, String category, bool isGenderCategory) {
    // Get icon for each category
    IconData categoryIcon = _getCategoryIcon(category, isGenderCategory);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserCategories(initialCategory: category),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Category Icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                categoryIcon,
                color: Color(0xFF6C4024),
                size: 22.sp,
              ),
            ),
            SizedBox(width: 16.w),
            // Category Name
            Text(
              category,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            // Forward Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  // Get appropriate icon for each category
  IconData _getCategoryIcon(String category, bool isGenderCategory) {
    if (isGenderCategory) {
      switch (category) {
        case 'Men':
          return Icons.man;
        case 'Women':
          return Icons.woman;
        case 'Kids':
          return Icons.child_care;
        case 'Unisex':
          return Icons.people;
        default:
          return Icons.person;
      }
    } else {
      switch (category) {
        case 'Apparel':
          return Icons.dry_cleaning;
        case 'Shoes':
          return Icons.shopping_bag;
        case 'Watches':
          return Icons.watch;
        case 'Ornaments':
          return Icons.diamond;
        case 'Sunglasses':
          return Icons.visibility;
        default:
          return Icons.category;
      }
    }
  }
}
