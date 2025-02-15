import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserAppbar extends StatelessWidget {
  const UserAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
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
        ],
      ),
    );
  }
}
