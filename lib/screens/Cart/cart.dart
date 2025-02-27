import 'package:capstone/widget/user_appbar.dart';
import 'package:flutter/material.dart';

class UserCart extends StatelessWidget {
  const UserCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child: Column(
              children: [UserAppbar()],
            ))));
  }
}
