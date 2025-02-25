import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SelectAColor extends StatefulWidget {
  const SelectAColor({super.key});

  @override
  _SelectAColorState createState() => _SelectAColorState();
}

class _SelectAColorState extends State<SelectAColor> {
  List<Color> selectedColors = [];

  void pickCustomColor() {
    Color pickedColor = Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pick a Color"),
        content: ColorPicker(
          pickerColor: pickedColor,
          onColorChanged: (c) => pickedColor = c,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                selectedColors.add(pickedColor);
              });
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50.h,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 251, 250, 250),
                elevation: 0.1,
                shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10))),
            onPressed: pickCustomColor,
            child: Text(
              "Add Color",
              style: TextStyle(color: Colors.black, fontSize: 15),
            ),
          ),
        ),
        SizedBox(height: 10),
        Text("Selected Colors:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 9),
        Wrap(
          spacing: 8,
          children: selectedColors
              .map((color) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
