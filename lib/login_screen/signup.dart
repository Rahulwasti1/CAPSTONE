import 'package:capstone/admin/admin_navbar.dart';
import 'package:capstone/service/auth_service.dart';
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

  // Validate form fields
  bool _validateFields() {
    if (nameContorller.text.isEmpty) {
      showSnackBar(context, "Please enter your name", isError: true);
      return false;
    }

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

    if (passwordContorller.text.length < 6) {
      showSnackBar(context, "Password must be at least 6 characters",
          isError: true);
      return false;
    }

    if (!isChecked) {
      showSnackBar(context, "Please agree to the Terms & Conditions",
          isError: true);
      return false;
    }

    return true;
  }

  // Signup function
  void _signUp() async {
    // Validate fields first
    if (!_validateFields()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Attempt user signup
      final result = await _authService.signUpUser(
          email: emailContorller.text,
          password: passwordContorller.text,
          name: nameContorller.text);

      if (result == "success") {
        showSnackBar(context, "Signup Successful");

        // Navigate to user screen and remove all previous routes, even if SharedPreferences failed
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => UserNavigation()),
            (route) => false);
      } else {
        // Show error message
        String errorMessage = result;
        if (result.contains("[firebase_auth]")) {
          if (result.contains("email-already-in-use")) {
            errorMessage = "Email is already in use. Try signing in instead.";
          } else if (result.contains("weak-password")) {
            errorMessage =
                "Password is too weak. Please use a stronger password.";
          } else if (result.contains("invalid-email")) {
            errorMessage = "Invalid email address.";
          } else {
            errorMessage = "Signup failed. Please try again.";
          }
        } else if (result.contains("PlatformException") &&
            result.contains("shared_preferences")) {
          // If it's a SharedPreferences error, we can still proceed with the account creation
          showSnackBar(context,
              "Account created, but some preferences couldn't be saved. You may need to log in again next time.",
              isError: false);

          // Navigate to user screen anyway
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => UserNavigation()),
              (route) => false);
          return;
        }

        showSnackBar(context, errorMessage, isError: true);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains("PlatformException") &&
          errorMessage.contains("shared_preferences")) {
        // SharedPreferences error but Firebase auth might have succeeded
        showSnackBar(context,
            "Account may have been created, but preferences couldn't be saved. You can try logging in.",
            isError: false);
      } else {
        showSnackBar(context, "An error occurred: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                      setState(() {
                        isChecked = !isChecked;
                      });
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
          SizedBox(height: 10.h),
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
                        onPressed: _signUp,
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
              const SizedBox(width: 4),
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
          SizedBox(height: 20.h),
        ]))));
  }
}
