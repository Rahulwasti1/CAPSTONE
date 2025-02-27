import 'package:capstone/admin/admin_navbar.dart';
import 'package:capstone/login_screen/login.dart';
import 'package:capstone/login_screen/onboarding1.dart';
import 'package:capstone/navigation_bar.dart';
import 'package:capstone/screens/Profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 255, 255, 255)),
            useMaterial3: true,
          ),
          // for keeping user login until logout

          home: AdminNavbar(),

          // home: StreamBuilder(
          //   stream: FirebaseAuth.instance.authStateChanges(),
          //   builder: (context, snapshot) {
          //     if (snapshot.connectionState == ConnectionState.active) {
          //       if (snapshot.hasData) {
          //         return UserNavigation(); // If user is logged in, navigate to UserNavigation
          //       } else {
          //         return Onboarding1(); // If user is NOT logged in, show login screen
          //       }
          //     }

          //     // While checking auth state, show a loading indicator
          //     return Scaffold(
          //       body: Center(
          //         child: CircularProgressIndicator(),
          //       ),
          //     );
          //   },
          // ),
        );
      },
    );
  }
}
