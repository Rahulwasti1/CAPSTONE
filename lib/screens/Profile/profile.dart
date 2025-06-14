import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/login.dart';
import 'package:capstone/screens/home/profile_avatar.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:capstone/screens/Profile/edit_profile.dart';
import 'package:capstone/screens/Profile/info_app_screen.dart';
import 'package:capstone/screens/Profile/privacy_policy_screen.dart';
import 'package:capstone/screens/Profile/terms_conditions_screen.dart';
import 'package:capstone/providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  // Static variable to cache the username.
  static String? cachedUsername;
  static String? cachedPhotoUrl;
  static String? cachedPhotoBase64;

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String username = "";

  Future<void> _getUsername() async {
    // Check if the username is already cached.
    if (UserProfile.cachedUsername != null) {
      setState(() {
        username = UserProfile.cachedUsername!;
      });
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // First try users collection (new)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // If not found, try userData collection (old)
        if (!userDoc.exists) {
          userDoc = await FirebaseFirestore.instance
              .collection('userData')
              .doc(user.uid)
              .get();
        }

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String name = userData['username'] ?? userData['name'] ?? 'User';

          // Cache all user data
          UserProfile.cachedUsername = name;
          UserProfile.cachedPhotoUrl = userData['photoUrl'];
          UserProfile.cachedPhotoBase64 = userData['photoBase64'];

          setState(() {
            username = name;
          });
        }
      } catch (e) {
        developer.log('Error getting user data: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16.sp,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown.shade600, Colors.brown.shade800],
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  await _performLogout(context);
                },
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Perform logout operations
  Future<void> _performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: CustomColors.secondaryColor,
            ),
          );
        },
      );

      // Clear cached user data
      UserProfile.cachedUsername = null;
      UserProfile.cachedPhotoUrl = null;
      UserProfile.cachedPhotoBase64 = null;

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => UserLogin()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
      developer.log('Logout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              UserAppbar(text: "Profile"),

              // Avatar with edit icon
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: ProfileAvatar(
                      circle: 60,
                      imageUrl: UserProfile.cachedPhotoUrl,
                      imageBase64: UserProfile.cachedPhotoBase64,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: CustomColors.secondaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                currentName: username,
                                currentPhotoUrl: UserProfile.cachedPhotoUrl,
                                currentPhotoBase64:
                                    UserProfile.cachedPhotoBase64,
                              ),
                            ),
                          );

                          if (result != null && mounted) {
                            setState(() {
                              username = result['username'];
                              UserProfile.cachedUsername = result['username'];
                              UserProfile.cachedPhotoUrl = result['photoUrl'];
                              UserProfile.cachedPhotoBase64 =
                                  result['photoBase64'];
                            });
                          }
                        },
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        padding: EdgeInsets.all(8.r),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),
              Text(
                username.isEmpty
                    ? 'Loading...'
                    : username[0].toUpperCase() +
                        username.substring(1).toLowerCase(),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              SizedBox(height: 17.h),

              Padding(
                padding: const EdgeInsets.only(right: 300),
                child: Text(
                  "Account",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: const EdgeInsets.only(left: 19),
                child: IconsandText(
                    icon: Icons.person,
                    text: "Personal Data",
                    icon1: Icons.arrow_forward_ios_rounded,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentName: username,
                            currentPhotoUrl: UserProfile.cachedPhotoUrl,
                            currentPhotoBase64: UserProfile.cachedPhotoBase64,
                          ),
                        ),
                      );

                      if (result != null && mounted) {
                        setState(() {
                          username = result['username'];
                          UserProfile.cachedUsername = result['username'];
                          UserProfile.cachedPhotoUrl = result['photoUrl'];
                          UserProfile.cachedPhotoBase64 = result['photoBase64'];
                        });
                      }
                    }),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: const EdgeInsets.only(right: 300),
                child: Text(
                  "Support",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              SizedBox(height: 11.h),
              Padding(
                padding: const EdgeInsets.only(left: 19),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Row(
                      children: [
                        Container(
                          height: 33.h,
                          width: 33.w,
                          decoration: BoxDecoration(
                            color: CustomColors.secondaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 18.w),
                        Text(
                          "Dark Mode",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Spacer(),
                        Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme();
                          },
                          activeColor: CustomColors.secondaryColor,
                          activeTrackColor:
                              CustomColors.secondaryColor.withOpacity(0.3),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 5.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.info,
                      text: "Info App",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InfoAppScreen(),
                          ),
                        );
                      })),
              SizedBox(height: 5.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.privacy_tip,
                      text: "Privacy Policy",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      })),
              SizedBox(height: 5.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.gavel,
                      text: "Terms and Conditions",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsConditionsScreen(),
                          ),
                        );
                      })),

              SizedBox(height: 5.h),
              Padding(
                padding: const EdgeInsets.only(left: 19),
                child: IconsandText(
                  icon: Icons.logout,
                  text: "Logout",
                  icon1: null,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// for making Icons and text

class IconsandText extends StatelessWidget {
  final IconData icon;
  final String text;
  final IconData? icon1;

  final VoidCallback onTap;

  const IconsandText(
      {super.key,
      required this.icon,
      required this.icon1,
      required this.text,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
                height: 33.h,
                width: 33.w,
                decoration: BoxDecoration(
                    color: CustomColors.secondaryColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  icon,
                  color: Colors.white,
                )),
            SizedBox(
              width: 18.w,
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            Spacer(),
            if (icon1 != null)
              Icon(
                icon1,
                size: 15,
                color: theme.iconTheme.color?.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}
