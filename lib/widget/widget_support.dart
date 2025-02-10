import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomListViewBuilder {
  final List<Map<String, dynamic>> buttonData = [
    {"icon": Icons.home, "text": "Home"},
    {"icon": Icons.favorite, "text": "Likes"},
    {"icon": Icons.settings, "text": "Settings"},
    {"icon": Icons.person, "text": "Profile"},
  ];

  Widget buildListView() {
    return Align(
      child: Transform.translate(
        offset: Offset(-4.w, 0.h),
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: buttonData.length,
            separatorBuilder: (context, index) => SizedBox(width: 14),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFf8f3f0),
                        elevation: 0.1,
                        shape: CircleBorder(),
                        minimumSize: Size(70, 70),
                      ),
                      child: Icon(
                        buttonData[index]["icon"],
                        size: 30,
                        color: Colors.brown,
                      ),
                    ),
                    SizedBox(height: 5), // Space between icon & text
                    Text(
                      buttonData[index]["text"],
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
