import 'package:capstone/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserAppbar extends StatelessWidget {
  final String text;
  const UserAppbar({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserNavigation()));
              },
              style: ElevatedButton.styleFrom(
                elevation: 0.1,
                backgroundColor: Colors.white,
                minimumSize: Size(10.h, 40.w),
                shape: CircleBorder(
                    side: BorderSide(
                        color: const Color.fromARGB(255, 241, 239, 239),
                        width: 0.5)),
              ),
              child: Icon(Icons.arrow_back,
                  size: 20.sp, color: const Color.fromARGB(255, 31, 31, 30))),
          SizedBox(width: 70.w),
          
Text(
  text,
  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
)
        ],
      ),
    );
  }
}
