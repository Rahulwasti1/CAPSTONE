import 'package:capstone/constants/colors.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Homeappbar extends StatelessWidget {
  const Homeappbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 15.w), // Padding for overall alignment
      child: Row(
        children: [
          GestureDetector(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()));
            },
            child: Container(
              
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: CustomColors.secondaryColor,
                  image: DecorationImage(
                      image: AssetImage("assets/images/profile.png"),
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
                "Rahul Wasti",
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
