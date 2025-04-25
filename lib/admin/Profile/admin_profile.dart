import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String adminName = "Rahul Wasti";
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  // Fetch admin name from Firestore
  Future<void> _fetchAdminData() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        DocumentSnapshot adminDoc =
            await _firestore.collection('adminData').doc(userId).get();

        if (adminDoc.exists) {
          setState(() {
            adminName = adminDoc['name'] ?? "Shaujanya Piya";
          });
        }
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),

                // Profile Header
                Text(
                  "PROFILE",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 24.h),

                // Profile Picture
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFFF5F1EA),
                      radius: 60.r,
                      child: CircleAvatar(
                        backgroundColor: Color(0xFF6C4024),
                        radius: 55.r,
                        child: Text(
                          adminName.isNotEmpty
                              ? adminName[0].toUpperCase()
                              : "A",
                          style: TextStyle(
                            fontSize: 45.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Edit profile icon
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Color(0xFF6C4024),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Admin Name
                Text(
                  adminName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 32.h),

                // Settings Menu Items
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: "Your Profile",
                  hasChevron: true,
                  onTap: () {},
                ),

                _buildSettingsItem(
                  icon: Icons.article_outlined,
                  title: "View Orders",
                  hasChevron: true,
                  onTap: () {},
                ),

                _buildSettingsItem(
                  icon: Icons.nightlight_outlined,
                  title: "Dark Mode",
                  hasSwitch: true,
                  switchValue: isDarkMode,
                  onSwitchChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  },
                ),

                _buildSettingsItem(
                  icon: Icons.help_outline,
                  title: "Help Center",
                  hasChevron: true,
                  onTap: () {},
                ),

                _buildSettingsItem(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  hasSwitch: true,
                  switchValue: notificationsEnabled,
                  onSwitchChanged: (value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),

                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: "Privacy Policy",
                  hasChevron: true,
                  onTap: () {},
                ),

                _buildSettingsItem(
                  icon: Icons.description_outlined,
                  title: "Terms and Agreements",
                  hasChevron: true,
                  onTap: () {},
                ),

                _buildSettingsItem(
                  icon: Icons.logout,
                  title: "Log-out",
                  hasChevron: true,
                  onTap: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      // Navigate to login screen
                      Navigator.of(context).pushReplacementNamed('/login');
                    } catch (e) {
                      print("Error signing out: $e");
                    }
                  },
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build settings items
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    bool hasChevron = false,
    bool hasSwitch = false,
    bool switchValue = false,
    VoidCallback? onTap,
    Function(bool)? onSwitchChanged,
  }) {
    return InkWell(
      onTap: hasSwitch ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(0xFF6C4024),
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
              ),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: Color(0xFF6C4024),
                inactiveTrackColor: Colors.grey.withOpacity(0.5),
              ),
            if (hasChevron)
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
