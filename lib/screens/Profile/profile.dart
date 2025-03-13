import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/login.dart';
import 'package:capstone/screens/home/profile_avatar.dart';
import 'package:capstone/widget/user_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  // Static variable to cache the username.
  static String? cachedUsername;

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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userData')
          .doc(user.uid)
          .get();

      String name = userDoc['name'] ?? 'User';
      // Cache the username.
      UserProfile.cachedUsername = name;
      setState(() {
        username = name;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              UserAppbar(),
              Container(
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: profileAvatar(
                    circle: 60,
                  )),
              // Align(
              //     child: Transform.translate(
              //   offset: Offset(30.w, -40.h),
              //   child: ElevatedButton(
              //       onPressed: () {
              //         print("Edit Profile Button Clicked");
              //       },
              //       style: ElevatedButton.styleFrom(
              //         minimumSize: Size(25.w, 25.h),
              //         backgroundColor: CustomColors.secondaryColor,
              //         elevation: 0.01,
              //         shape: CircleBorder(),
              //       ),
              //       child: Icon(
              //         Icons.edit,
              //         color: Colors.white,
              //       )),
              // )),
              SizedBox(height: 10.h),
              Text(
                username.isEmpty
                    ? 'Loading...'
                    : username[0].toUpperCase() +
                        username.substring(1).toLowerCase(),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 17.h),

              Padding(
                padding: const EdgeInsets.only(right: 300),
                child: Text(
                  "Account",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: const EdgeInsets.only(left: 19),
                child: IconsandText(
                    icon: Icons.person,
                    text: "Personal Data",
                    icon1: Icons.arrow_forward_ios_rounded,
                    onTap: () {
                      print("object");
                    }),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: const EdgeInsets.only(right: 300),
                child: Text(
                  "Support",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 11.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.dark_mode,
                      text: "Dark Mode",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        print("object");
                      })),
              SizedBox(height: 5.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.info,
                      text: "Info App",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        print("object");
                      })),
              SizedBox(height: 5.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.privacy_tip,
                      text: "Privacy Policy",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        print("object");
                      })),
              SizedBox(height: 5.h),
              Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: IconsandText(
                      icon: Icons.gavel,
                      text: "Terms and Conditions",
                      icon1: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        print("object");
                      })),

              SizedBox(height: 5.h),
              Padding(
                padding: const EdgeInsets.only(left: 19),
                child: IconsandText(
                  icon: Icons.logout,
                  text: "Logout",
                  icon1: null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserLogin()),
                    );
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
    return GestureDetector(
      onTap: onTap,
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Spacer(),
          IconButton(
              onPressed: () {},
              icon: Icon(
                icon1,
                size: 15,
              ))
        ],
      ),
    );
  }
}
