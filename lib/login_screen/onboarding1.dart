import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 445),
        child: Center(
          child: Column(
            children: [
              Text(
                "Smart Shopping Starts Here",
                style: TextStyle(
                    color: CustomColors.secondaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Try Before You Buy!",
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      "Tired of returns? Our AI-powered virtual fitting room ensures a perfect match every time!",
                      style: TextStyle(
                          color: const Color.fromARGB(255, 121, 120, 120)),
                    ),
                    SizedBox(height: 25),
                    ElevatedButton(
                        onPressed: () {
                          print("Button Clicked");
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: CustomColors.secondaryColor,
                            minimumSize: Size(400.w, 50.h)),
                        child: Text(
                          "Let's Get Started",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Row(
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UserLogin()));
                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: CustomColors.secondaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: CustomColors.secondaryColor),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    ])));
  }
}
