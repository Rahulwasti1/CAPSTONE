import 'package:flutter/material.dart';

class profileAvatar extends StatelessWidget {
  final double circle;

  const profileAvatar({super.key, required this.circle});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: circle,
      child: Image.asset(
        "assets/images/userr.png",
      ),
    );
  }
}
