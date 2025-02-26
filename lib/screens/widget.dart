import 'package:capstone/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomWidget {
  static Widget customButton({
    required VoidCallback onPressed,
    required String text,
    required double width,
    required double height,
  }) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: CustomColors.secondaryColor,
            minimumSize: Size(width, height)),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ));
  }
}
