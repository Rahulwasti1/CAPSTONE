import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Addsize extends StatefulWidget {
  const Addsize({super.key});

  @override
  State<Addsize> createState() => _AddsizeState();
}

class _AddsizeState extends State<Addsize> {
  List<String> sizeOptions = ["S", "M", "L", "XL", "XXL"];
  List<String> selectedSize = [];

  // If multiple same size user tries to select

  // void toggleSize(String size) {
  //   setState(() {
  //     if (selectedSize.contains(size)) {
  //       selectedSize.remove(size); // Remove if already selected
  //     } else {
  //       selectedSize.add(size); // Add if not selected
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 360.w,
            height: 53.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButton<String>(
                  isExpanded: true,
                  hint: Text("Select Size"),
                  items: sizeOptions.map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (_) {}),
            ),
          ),
          // SizedBox(height: 20),
          // Text("Selected Colors:",
          //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          // Wrap(
          //   spacing: 8,
          //   children: selectedSize
          //       .map((Size) => Container(
          //             width: 40,
          //             height: 35,
          //             decoration: BoxDecoration(
          //               shape: BoxShape.circle,
          //             ),
          //           ))
          //       .toList(),
          // ),
        ],
      ),
    );
  }
}
