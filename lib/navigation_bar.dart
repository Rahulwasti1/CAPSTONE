import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/cart/cart.dart';
import 'package:capstone/screens/categories/categories.dart';
import 'package:capstone/screens/home/userhome.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:capstone/providers/theme_provider.dart';
// import 'package:capstone/screens/TryOn/try_on.dart'; // Removed unused import
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class UserNavigation extends StatefulWidget {
  const UserNavigation({super.key});

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  List screens = [
    Userhome(),
    UserCategories(),
    UserCategories(), // Changed from UserTryOn() to UserCategories() as a placeholder
    UserCart(),
    UserProfile(),
  ];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load user data when navigation bar is created
    _loadUserProfileData();
  }

  // Load user profile data to ensure it's available throughout the app
  Future<void> _loadUserProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Try both collections
      DocumentSnapshot? userDoc;

      // Try users collection first
      userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // If not found, try userData collection
      if (!userDoc.exists) {
        userDoc = await FirebaseFirestore.instance
            .collection('userData')
            .doc(user.uid)
            .get();
      }

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Cache user data in UserProfile static variables
        String username = userData['username'] ??
            userData['name'] ??
            user.displayName ??
            user.email?.split('@')[0] ??
            "Account";

        UserProfile.cachedUsername = username;
        UserProfile.cachedPhotoUrl = userData['photoUrl'];
        UserProfile.cachedPhotoBase64 = userData['photoBase64'];
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        // If no document exists but display name is available
        UserProfile.cachedUsername = user.displayName;
      } else if (user.email != null) {
        // Use email as fallback
        UserProfile.cachedUsername = user.email!.split('@')[0];
      }
    } catch (e) {
      developer.log('Error loading user profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: theme.scaffoldBackgroundColor,
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: SingleChildScrollView(
            child: BottomAppBar(
              elevation: 1,
              height: 50,
              shape: CircularNotchedRectangle(),
              notchMargin: 10,
              color: theme.cardColor,
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
                            : theme.iconTheme.color?.withOpacity(0.6),
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
                            : theme.iconTheme.color?.withOpacity(0.6),
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
                            : theme.iconTheme.color?.withOpacity(0.6),
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
                            : theme.iconTheme.color?.withOpacity(0.6),
                      ))
                ],
              ),
            ),
          ),
          body: screens[currentIndex],
        );
      },
    );
  }
}
