import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 25),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(height: 80.h),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.brown),
                    height: 48.h,
                    width: 50.w,
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 52.w),
                        child: Text(
                          " 👋 Hello!",
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10.w),
                        child: Text(
                          "Rahul Wasti",
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  SizedBox(width: 90.w),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          print("Notification Button Clicked");
                        },
                        style: ElevatedButton.styleFrom(
                            elevation: 0.1,
                            backgroundColor: Colors.white,
                            minimumSize: Size(10.h, 40.w),
                            shape: CircleBorder()),
                        child: Icon(Icons.notifications,
                            size: 20.sp,
                            color: const Color.fromARGB(255, 31, 31, 30))),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  SizedBox(
                    width: 310,
                    child: TextField(
                      decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search",
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.w, horizontal: 10.h),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(50.w, 43.h),
                          padding: EdgeInsets.zero),
                      child: SizedBox(
                        child: Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      )),
                  SizedBox(height: 10.h),
                  
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
