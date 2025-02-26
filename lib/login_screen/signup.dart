import 'package:capstone/Service/auth_service.dart';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/login.dart';
import 'package:capstone/navigation_bar.dart';
import 'package:capstone/screens/widget.dart';
import 'package:capstone/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserSignup extends StatefulWidget {
  const UserSignup({super.key});

  @override
  State<UserSignup> createState() => _UserSignupState();
}

class _UserSignupState extends State<UserSignup> {
  bool isChecked = false;
  bool _isObsecure = true;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  // Signup function to handle user registration

  void _signUp() async {
    setState(() {
      isLoading = true;
    });

    // calling the method
    final result = await _authService.signUpUser(
        email: emailContorller.text,
        password: passwordContorller.text,
        name: nameContorller.text);

    if (result == "success") {
      showSnackBar(context, "Signup Successful");

      // navigating to the next screen with the message

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => UserNavigation()));
    } else
      {
        setState(() {
          isLoading = false;
        });
        showSnackBar(context, "Signup Failed $result");
      };
  }

  // controller
  TextEditingController nameContorller = TextEditingController();
  TextEditingController emailContorller = TextEditingController();
  TextEditingController passwordContorller = TextEditingController();

  Widget customTextField({
    String? text,
    required String hintText,
    bool isPassword = false,
    required TextEditingController controller,
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
            controller: controller,
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
      onPressed: () => print("Login"),
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
          SizedBox(height: 20.h),
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
          customTextField(
              text: "Name",
              hintText: "Ex. Rahul Wasti",
              controller: nameContorller),
          const SizedBox(height: 20),
          customTextField(
              text: "Email",
              hintText: "example@gmail.com",
              controller: emailContorller),
          const SizedBox(height: 20),
          customTextField(
              text: "Password",
              hintText: "***************",
              isPassword: true,
              controller: passwordContorller),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: CustomColors.secondaryColor,
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
                      offset: Offset(-60.w, 0.h),
                      child: Text.rich(
                        TextSpan(
                          text: "Agree with ",
                          children: [
                            TextSpan(
                              text: "Terms & Conditions",
                              style: TextStyle(
                                  color: CustomColors.secondaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: CustomColors.secondaryColor),
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
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: CustomWidget.customButton(
                        onPressed:
                            _signUp, // Removed extra arrow function "() => _signUp"
                        text: "Sign Up",
                        width: double.infinity,
                        height: 52.h,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: 32.h),
          const Text(
            "───── Or sign up with ─────",
            style: TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
          ),
          SizedBox(height: 29.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              customLoginIcon(image: "assets/images/apple.png"),
              const SizedBox(width: 15),
              customLoginIcon(image: "assets/images/google.png"),
              const SizedBox(width: 15),
              customLoginIcon(image: "assets/images/facebook.png"),
            ],
          ),
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an Account?"),
              SizedBox(width: 4.w),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserLogin()));
                },
                child: Text(
                  "Sign In",
                  style: TextStyle(
                      color: CustomColors.secondaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: CustomColors.secondaryColor),
                ),
              ),
            ],
          ),
        ]))));
  }
}
