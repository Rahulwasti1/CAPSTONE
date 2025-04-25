import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message,
    {bool isError = false, Duration duration = const Duration(seconds: 3)}) {
  final snackBar = SnackBar(
    content: Text(
      message,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    ),
    backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    margin: EdgeInsets.all(10),
    duration: duration,
    action: SnackBarAction(
      label: 'DISMISS',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
