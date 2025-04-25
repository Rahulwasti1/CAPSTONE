import 'package:capstone/service/admin_auth.dart';
import 'package:capstone/service/auth_service.dart';
import 'package:capstone/constants/colors.dart';
import 'package:capstone/login_screen/signup.dart';
import 'package:capstone/screens/widget.dart';
import 'package:capstone/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  bool isChecked = false;
  bool _isObsecure = true;
  bool isLoading = false;
  bool isAdmin = false;
  final AuthService _authService = AuthService();
  final AdminAuthService _adminAuthService = AdminAuthService();

  // Validate form fields
  bool _validateFields() {
    if (emailContorller.text.isEmpty) {
      showSnackBar(context, "Please enter your email", isError: true);
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(emailContorller.text)) {
      showSnackBar(context, "Please enter a valid email address",
          isError: true);
      return false;
    }

    if (passwordContorller.text.isEmpty) {
      showSnackBar(context, "Please enter your password", isError: true);
      return false;
    }

    return true;
  }

  // Login function
  Future<void> _login() async {
    if (_validateFields()) {
      try {
        setState(() {
          isLoading = true;
        });
        if (isAdmin) {
          // Admin login
          String result = await _adminAuthService.loginAdmin(
            email: emailContorller.text.trim(),
            password: passwordContorller.text.trim(),
          );

          if (result == "success") {
            developer.log('Admin login successful');

            // Pop back to authentication wrapper
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } else {
            throw FirebaseAuthException(code: 'invalid-login', message: result);
          }
        } else {
          // User login
          String result = await _authService.loginUser(
            email: emailContorller.text.trim(),
            password: passwordContorller.text.trim(),
          );

          if (result == "success") {
            developer.log('User login successful');

            // Pop back to authentication wrapper
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } else {
            throw FirebaseAuthException(code: 'invalid-login', message: result);
          }
        }
      } catch (e) {
        developer.log('Login error: $e');
        String errorMessage = 'Login failed. Please check your credentials.';
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found' || e.code == 'wrong-password') {
            errorMessage = 'Invalid email or password.';
          } else if (e.code == 'user-disabled') {
            errorMessage = 'This account has been disabled.';
          } else {
            errorMessage = e.message ?? errorMessage;
          }
        }
        showSnackBar(context, errorMessage, isError: true);
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
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
      onPressed: () => developer.log("Login"),
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
              ? Center(
                  child: CircularProgressIndicator(
                    color: CustomColors.secondaryColor,
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: CustomWidget.customButton(
                        onPressed: _login,
                        text: "Sign In",
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
