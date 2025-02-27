import 'package:capstone/admin/home/admin_home.dart';
import 'package:capstone/admin/profile/admin_profile.dart';
import 'package:capstone/admin/add_product/add_product.dart';
import 'package:capstone/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class AdminNavbar extends StatefulWidget {
  const AdminNavbar({super.key});

  @override
  State<AdminNavbar> createState() => _AdminNavbarState();
}

class _AdminNavbarState extends State<AdminNavbar> {
  List screens = [
    AdminHome(),
    AdminAddProduct(),
    AdminProfile(),
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
              currentIndex = 1;
            });
          },
          shape: CircleBorder(),
          backgroundColor: CustomColors.secondaryColor,
          child: Icon(
            Icons.add,
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
                    currentIndex = 2;
                  });
                },
                icon: Icon(
                  Iconsax.user,
                  size: 28,
                  color: currentIndex == 2
                      ? CustomColors.secondaryColor
                      : Colors.grey,
                )),
          ],
        ),
      ),
      body: screens[currentIndex],
    );
  }
}
