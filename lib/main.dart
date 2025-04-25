import 'package:capstone/admin/admin_navbar.dart';
import 'package:capstone/login_screen/onboarding1.dart';
import 'package:capstone/navigation_bar.dart';
import 'package:capstone/provider/cart_provider.dart';
import 'package:capstone/provider/favourite_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is PlatformException) {
      PlatformException e = details.exception as PlatformException;
      if (e.code == 'channel-error' &&
          e.message != null &&
          e.message!.contains(
              'dev.flutter.pigeon.shared_preferences_foundation.LegacyUserDefaultsApi.getAll')) {
        print('Caught SharedPreferences error: ${e.message}');
        // Continue execution
        return;
      }
    }
    FlutterError.presentError(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final cartProvider = CartProvider();
            return cartProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final favoriteProvider = FavoriteProvider();
            return favoriteProvider;
          },
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: const AuthenticationWrapper(),
          );
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while connection state is waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in (auth state has data)
        if (snapshot.hasData && snapshot.data != null) {
          // Check if the user is admin or regular user
          return FutureBuilder<String?>(
            future: _getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Ensuring login status is saved to SharedPreferences
              _saveLoginStatus(
                  snapshot.data!.uid, roleSnapshot.data ?? 'buyer');

              // Return appropriate screen based on user role
              if (roleSnapshot.data == 'admin') {
                return AdminNavbar();
              } else {
                return UserNavigation();
              }
            },
          );
        }

        // Checking if we should show onboarding or direct to login
        return FutureBuilder<bool>(
          future: _checkFirstLaunch(),
          builder: (context, launchSnapshot) {
            if (launchSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return Onboarding1();
          },
        );
      },
    );
  }

  // Get user role from Firestore
  Future<String?> _getUserRole(String uid) async {
    try {
      // First check admin collection
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('adminData')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        return 'admin';
      }

      // If not admin, check user collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('userData')
          .doc(uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        try {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          return userData['role'] ?? 'buyer';
        } catch (e) {
          print('Error parsing user data: $e');
          return 'buyer'; // Default on parsing error
        }
      }

      // Also check the users collection (alternate location)
      try {
        DocumentSnapshot alternateUserDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (alternateUserDoc.exists && alternateUserDoc.data() != null) {
          Map<String, dynamic> userData =
              alternateUserDoc.data() as Map<String, dynamic>;
          return userData['role'] ?? 'buyer';
        }
      } catch (e) {
        print('Error checking alternate user location: $e');
      }

      return 'buyer'; // Default role
    } catch (e) {
      print('Error getting user role: $e');
      return 'buyer'; // Default role on error
    }
  }

  // Save login status to SharedPreferences
  Future<void> _saveLoginStatus(String uid, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userRole', role);
      await prefs.setString('userId', uid);
      print('Login status saved: uid=$uid, role=$role');
    } catch (e) {
      print('Error saving login status: $e');
    }
  }

  // Check if this is the first app launch
  Future<bool> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check both hasLaunched (general app launch) and hasSeenOnboarding
      final hasLaunched = prefs.getBool('hasLaunched') ?? false;
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      // If it's first launch, set the hasLaunched flag
      if (!hasLaunched) {
        await prefs.setBool('hasLaunched', true);
      }

      // We show onboarding if either the app has never been launched
      // or if the user hasn't completed the onboarding flow
      return !hasLaunched || !hasSeenOnboarding;
    } catch (e) {
      print('Error checking first launch: $e');
      return true; // Assume first launch on error
    }
  }
}
