import 'package:flutter/material.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 100,
                    width: 100,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Getting Started",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Welcome back, glad to see you again",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            customLoginTextField(
              fieldname: "Email",
              name: "E-mail",
            )
          ],
        ),
      ),
    );
  }
}

class customLoginTextField extends StatelessWidget {
  final String name;
  final String fieldname;
  const customLoginTextField(
      {super.key, required this.name, required this.fieldname});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 290),
          child: Column(
            children: [
              SizedBox(height: 40),
              Text(
                name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            decoration: InputDecoration(hintText: fieldname),
          ),
        )
      ],
    );
  }
}
