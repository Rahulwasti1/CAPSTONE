import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminAppbar extends StatelessWidget {
  final String name;
  const AdminAppbar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return AppBar(backgroundColor: Colors.white, actions: [
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: IconButton.styleFrom(
                side: BorderSide(
                  width: 2.w,
                  color: Color.fromARGB(255, 241, 239, 239),
                ),
              ),
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
        ],
      ),
      Spacer(),
      Padding(
        padding: const EdgeInsets.only(right: 140),
        child: Text(
          name,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
        ),
      )
    ]);
  }
}
