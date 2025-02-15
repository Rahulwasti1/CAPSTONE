import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/Cart/cart.dart';
import 'package:capstone/screens/Categories/categories.dart';
import 'package:capstone/screens/Home/userhome.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:capstone/screens/TryOn/tryOn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserNavigation extends StatefulWidget {
  const UserNavigation({super.key});

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  List screens = [
    Userhome(),
    UserCategories(),
    UserTryOn(),
    UserCart(),
    UserProfile(),
  ];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        height: 100.h,
        width: 62.w,
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              currentIndex = 2;
            });
          },
          shape: CircleBorder(),
          backgroundColor: CustomColors.secondaryColor,
          child: Icon(
            Icons.camera_front,
            size: 32,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      bottomNavigationBar: BottomAppBar(
        elevation: 1,
        height: 50,
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        color: const Color.fromARGB(255, 252, 252, 252),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    currentIndex = 0;
                  });
                },
                icon: Icon(
                  Icons.home,
                  size: 30,
                  color: currentIndex == 0
                      ? CustomColors.secondaryColor
                      : Colors.grey,
                )),
            SizedBox(width: 10.w),
            IconButton(
                onPressed: () {
                  setState(() {
                    currentIndex = 1;
                  });
                },
                icon: Icon(
                  Icons.category,
                  size: 30,
                  color: currentIndex == 1
                      ? CustomColors.secondaryColor
                      : Colors.grey,
                )),
            SizedBox(width: 75),
            IconButton(
                onPressed: () {
                  setState(() {
                    currentIndex = 3;
                  });
                },
                icon: Icon(
                  Icons.shopping_cart,
                  size: 27,
                  color: currentIndex == 3
                      ? CustomColors.secondaryColor
                      : Colors.grey,
                )),
            SizedBox(width: 10.w),
            IconButton(
                onPressed: () {
                  setState(() {
                    currentIndex = 4;
                  });
                },
                icon: Icon(
                  Icons.person,
                  size: 27,
                  color: currentIndex == 4
                      ? CustomColors.secondaryColor
                      : Colors.grey,
                ))
          ],
        ),
      ),
      body: screens[currentIndex],
    );
  }
}
