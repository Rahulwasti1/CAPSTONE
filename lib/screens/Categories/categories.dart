import 'package:capstone/widget/user_appbar.dart';
import 'package:flutter/material.dart';

class UserCategories extends StatelessWidget {
  const UserCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Column(
          children: [UserAppbar()],
        )));
  }
}
