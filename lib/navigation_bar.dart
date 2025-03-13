import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/cart/cart.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:capstone/screens/home/userhome.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:capstone/screens/TryOn/tryOn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

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
      resizeToAvoidBottomInset: false,
      floatingActionButton: SizedBox(
        height: 90.h,
        width: 60.w,
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              currentIndex = 2;
            });
          },
          shape: CircleBorder(),
          backgroundColor: CustomColors.secondaryColor,
          child: SizedBox(
              height: 25, child: Image.asset("assets/images/scanner.png")),
          // child: Icon(
          //   Icons.camera_front,
          //   size: 32,
          //   color: Colors.white,
          // ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      bottomNavigationBar: SingleChildScrollView(
        child: BottomAppBar(
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
                    Iconsax.home,
                    size: 28,
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
                    Iconsax.category,
                    size: 25,
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
                    Iconsax.shopping_cart,
                    size: 25,
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
                    Iconsax.user,
                    size: 25,
                    color: currentIndex == 4
                        ? CustomColors.secondaryColor
                        : Colors.grey,
                  ))
            ],
          ),
        ),
      ),
      body: screens[currentIndex],
    );
  }
}
