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
                backgroundColor: Theme.of(context).cardColor,
                minimumSize: Size(10.h, 40.w),
                shape: CircleBorder(
                    side: BorderSide(
                        color: Theme.of(context).dividerColor, width: 0.5)),
              ),
              child: Icon(Icons.arrow_back,
                  size: 20.sp, color: Theme.of(context).iconTheme.color)),
          SizedBox(width: 70.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          )
        ],
      ),
    );
  }
}
