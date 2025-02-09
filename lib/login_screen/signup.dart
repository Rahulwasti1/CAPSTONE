import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/login.dart';
import 'package:capstone/screens/widget.dart';
import 'package:flutter/material.dart';

class UserSignup extends StatefulWidget {
  const UserSignup({super.key});

  @override
  State<UserSignup> createState() => _UserSignupState();
}

class _UserSignupState extends State<UserSignup> {
  bool isChecked = false;
  bool _isObsecure = true;

  Widget customTextField({
    String? text,
    required String hintText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text != null)
          Padding(
            padding: const EdgeInsets.only(left: 27),
            child: Text(text, textAlign: TextAlign.left),
          ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 27),
          child: TextField(
            obscureText: isPassword ? _isObsecure : false,
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: isPassword
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _isObsecure = !_isObsecure;
                        });
                      },
                      icon: Icon(
                        _isObsecure ? Icons.visibility_off : Icons.visibility,
                      ),
                    )
                  : null,
              hintStyle: const TextStyle(fontSize: 14),
              filled: true,
              fillColor: const Color.fromARGB(255, 240, 238, 238),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color.fromARGB(255, 240, 238, 238)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color.fromARGB(255, 240, 238, 238)),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget customLoginIcon({required String image}) {
    return ElevatedButton(
      onPressed: () => print("Login with $image"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 0.1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(300),
        ),
        minimumSize: const Size(65, 65),
        padding: EdgeInsets.zero,
      ),
      child: SizedBox(
        height: 28,
        width: 30,
        child: Image.asset(image, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
                child: Column(children: [
          const SizedBox(height: 60),
          const Text(
            "Create Account",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Fill your information below or register \nwith your social account.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color.fromARGB(255, 97, 96, 96)),
          ),
          const SizedBox(height: 20),
          customTextField(text: "Name", hintText: "Ex. Rahul Wasti"),
          const SizedBox(height: 20),
          customTextField(text: "Email", hintText: "example@gmail.com"),
          const SizedBox(height: 20),
          customTextField(
            text: "Password",
            hintText: "***************",
            isPassword: true,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: CustomColors.primaryColor,
                  onChanged: (bool? newValue) {
                    setState(() {
                      isChecked = newValue ?? false;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Handle T&C click
                    },
                    child: Align(
                        child: Transform.translate(
                      offset: Offset(-80, 0),
                      child: Text.rich(
                        TextSpan(
                          text: "Agree with ",
                          children: [
                            TextSpan(
                              text: "Terms & Conditions",
                              style: TextStyle(
                                  color: CustomColors.primaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: CustomColors.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CustomWidget.customButton(
            onPressed: () => print("Sign Up"),
            text: "Sign Up",
            width: 375,
            height: 55,
          ),
          const SizedBox(height: 32),
          const Text(
            "───── Or sign up with ─────",
            style: TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Row(
              children: [
                customLoginIcon(image: "assets/images/apple.png"),
                const SizedBox(width: 15),
                customLoginIcon(image: "assets/images/google.png"),
                const SizedBox(width: 15),
                customLoginIcon(image: "assets/images/facebook.png"),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 70),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an Account?"),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => UserLogin()));
                  },
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                        color: CustomColors.primaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: CustomColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ]))));
  }
}
