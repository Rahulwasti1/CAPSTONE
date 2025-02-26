import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Homeappbar extends StatefulWidget {
  const Homeappbar({super.key});

  @override
  State<Homeappbar> createState() => _HomeappbarState();
}

class _HomeappbarState extends State<Homeappbar> {
  String username = "";
  bool isUsernameLoaded = false; //  tracking if the username is loaded

  // Fetching username form firebase
  Future<void> _getUsername() async {
    if (isUsernameLoaded)
      return; // Skipping fetching the username is already loaded
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Fetching the user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userData')
          .doc(user.uid)
          .get();

      // Fetching the 'name' field from the document
      setState(() {
        username = userDoc['name'] ?? 'User';
        isUsernameLoaded = true;
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
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: CustomColors.secondaryColor,
                  image: DecorationImage(
                      image: AssetImage("assets/images/profile.svg"),
                      fit: BoxFit.fill)),
              height: 48.h,
              width: 50.w,
            ),
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
                print("Notification Button Clicked");
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
