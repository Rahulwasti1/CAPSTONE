import 'package:capstone/Service/auth_service.dart';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/signup.dart';
import 'package:capstone/navigation_bar.dart';
import 'package:capstone/screens/widget.dart';
import 'package:capstone/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  bool isChecked = false;
  bool _isObsecure = true;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  // Signup function to handle user registration

  void _login() async {
    setState(() {
      isLoading = true;
    });

    // calling the method
    final result = await _authService.loginUser(
      email: emailContorller.text,
      password: passwordContorller.text,
    );

    if (result == "success") {
      showSnackBar(context, "Login Successful");

      // navigating to the next screen with the message

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => UserNavigation()));
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, "Login Failed $result");
    }
    ;
  }

  // Controller
  TextEditingController emailContorller = TextEditingController();
  TextEditingController passwordContorller = TextEditingController();

  Widget customTextField({
    String? text,
    required String hintText,
    required TextEditingController controller,
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
          const SizedBox(height: 60),
          const Text(
            "Sign In",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "Hi! Welcome back, you've been missed",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color.fromARGB(255, 97, 96, 96)),
          ),
          const SizedBox(height: 40),
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
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Handle T&C click
                    },
                    child: Align(
                      child: Transform.translate(
                          offset: Offset(103.w, 0.h),
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                                color: CustomColors.secondaryColor,
                                decoration: TextDecoration.underline,
                                decorationColor: CustomColors.secondaryColor),
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: CustomWidget.customButton(
                        onPressed:
                            _login, // Removed extra arrow function "() => _signUp"
                        text: "Sign Up",
                        width: double.infinity,
                        height: 52.h,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 38),
          const Text(
            "───── Or sign in with ─────",
            style: TextStyle(color: Color.fromARGB(255, 158, 158, 158)),
          ),
          const SizedBox(height: 30),
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
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an Account?"),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserSignup()));
                },
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                      color: CustomColors.secondaryColor,
                      decoration: TextDecoration.underline,
                      decorationColor: CustomColors.secondaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ]))));
  }
}
