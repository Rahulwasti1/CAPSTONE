import 'package:capstone/admin/add_product/add_product.dart';
import 'package:capstone/admin/home/admin_home.dart';
import 'package:capstone/admin/profile/admin_profile.dart';
import 'package:capstone/constants/colors.dart';
import 'package:flutter/material.dart';
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
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              currentIndex = 1;
            });
          },
          shape: const CircleBorder(),
          backgroundColor: CustomColors.secondaryColor,
          child: Icon(
            Icons.add,
            color: Colors.white,
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomAppBar(
        elevation: 1,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color.fromARGB(255, 250, 249, 249),
        height: 50, // Reducing navbar height
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Iconsax.home, 0),
            const SizedBox(width: 60), // Spacing for Floating Action Button
            _buildNavItem(Iconsax.setting, 2),
          ],
        ),
      ),
      body: screens[currentIndex],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      child: Icon(
        icon,
        size: 24,
        color:
            currentIndex == index ? CustomColors.secondaryColor : Colors.grey,
      ),
    );
  }
}
