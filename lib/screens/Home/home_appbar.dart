import 'package:capstone/screens/home/profile_avatar.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;

class Homeappbar extends StatefulWidget {
  const Homeappbar({super.key});

  static String? cachedUsername;

  @override
  State<Homeappbar> createState() => _HomeappbarState();
}

class _HomeappbarState extends State<Homeappbar> {
  String username = "";
  String? photoUrl;
  String? photoBase64;

  Future<void> _getUserData() async {
    // Check if the username is already cached.
    if (UserProfile.cachedUsername != null) {
      setState(() {
        username = UserProfile.cachedUsername!;
        photoUrl = UserProfile.cachedPhotoUrl;
        photoBase64 = UserProfile.cachedPhotoBase64;
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

          // Cache the user data
          UserProfile.cachedUsername = name;
          UserProfile.cachedPhotoUrl = userData['photoUrl'];
          UserProfile.cachedPhotoBase64 = userData['photoBase64'];

          setState(() {
            username = name;
            photoUrl = userData['photoUrl'];
            photoBase64 = userData['photoBase64'];
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
    _getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 15.w), // Padding for overall alignment
      child: Row(
        children: [
          GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserProfile()));
              },
              child: ProfileAvatar(
                circle: 27,
                imageUrl: photoUrl,
                imageBase64: photoBase64,
              )
              // child: Container(
              //   decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(10),
              //       color: CustomColors.secondaryColor,
              //       image: DecorationImage(
              //           image: AssetImage("assets/images/profile.svg"),
              //           fit: BoxFit.fill)),
              //   height: 48.h,
              //   width: 50.w,
              // ),
              ),

          SizedBox(width: 8.w), // Space between image box and text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                " 👋 Hello!",
                style: TextStyle(fontSize: 14.sp),
              ),
              Text(
                username.isEmpty
                    ? 'Loading...'
                    : username[0].toUpperCase() +
                        username.substring(1).toLowerCase(),
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Spacer(), // Pushes the notification button to the right
          Align(
              child: Transform.translate(
            offset: Offset(15.w, 0.h),
            child: ElevatedButton(
              onPressed: () {
                developer.log("Notification Button Clicked");
              },
              style: ElevatedButton.styleFrom(
                elevation: 0.1,
                backgroundColor: Colors.white,
                minimumSize: Size(40.w, 40.h),
                shape: CircleBorder(),
                side: BorderSide(
                  color: const Color.fromARGB(255, 241, 239, 239),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.notifications,
                size: 24,
                color: Colors.black,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
