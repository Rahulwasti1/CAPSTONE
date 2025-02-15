import 'package:capstone/widget/User_AppBar.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
              child: Column(
            children: [UserAppbar()],
          ))),
    );
  }
}
