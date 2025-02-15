import 'package:capstone/widget/User_AppBar.dart';
import 'package:flutter/material.dart';

class UserTryOn extends StatefulWidget {
  const UserTryOn({super.key});

  @override
  State<UserTryOn> createState() => _UserTryOnState();
}

class _UserTryOnState extends State<UserTryOn> {
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
