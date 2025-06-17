import 'package:capstone/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:capstone/admin/debug_asset_manager.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String adminName = "Rahul Wasti";

  // Order statistics (will be fetched from Firebase)
  int pendingOrders = 7;
  int acceptedOrders = 12;
  int ongoingOrders = 5;
  int canceledOrders = 0;
  int completedOrders = 2;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
    _fetchOrderStatistics();
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
            adminName = adminDoc['name'] ?? "Admin";
          });
        }
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
  }

  // Fetch order statistics from Firestore
  // This is a placeholder - implement actual Firestore queries based on your data model
  Future<void> _fetchOrderStatistics() async {
    try {
      // Add your Firestore queries here to get actual order statistics
      // For now we're using placeholder values
    } catch (e) {
      print("Error fetching order statistics: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin greeting section
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F1EA),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Admin avatar
                      CircleAvatar(
                        backgroundColor: Color(0xFFF5F1EA),
                        radius: 30.r,
                        child: CircleAvatar(
                          backgroundColor: Color(0xFF6C4024),
                          radius: 27.r,
                          child: Text(
                            adminName.isNotEmpty
                                ? adminName[0].toUpperCase()
                                : "A",
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // Welcome text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome ${adminName.split(' ')[0]},",
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Order Overview Section
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F1EA),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ORDER OVERVIEW",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Order Status Items
                      _buildOrderStatusItem("Pending Order", pendingOrders,
                          Iconsax.clock, CustomColors.primaryColor),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                      _buildOrderStatusItem("Accepted Order", acceptedOrders,
                          Iconsax.tick_circle, Colors.green),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                      _buildOrderStatusItem("Ongoing Order", ongoingOrders,
                          Iconsax.truck, Colors.blue),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                      _buildOrderStatusItem("Canceled Order", canceledOrders,
                          Iconsax.close_circle, Colors.red),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

                      _buildOrderStatusItem("Completed Order", completedOrders,
                          Iconsax.tick_square, CustomColors.secondaryColor),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Quick Actions Section
                Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),

                // Quick action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickActionButton("Add Product", Iconsax.add_square,
                        CustomColors.secondaryColor),
                    _buildQuickActionButton(
                        "View Orders", Iconsax.document_text, Colors.orange),
                    _buildQuickActionButton(
                        "Settings", Iconsax.setting, Colors.blue),
                  ],
                ),

                SizedBox(height: 16.h),

                // Debug section (for development)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DebugAssetManager(),
                          ),
                        );
                      },
                      child: _buildQuickActionButton(
                          "Debug Images", Iconsax.image, Colors.purple),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Recent Products Section (Placeholder)
                Text(
                  "Recent Products",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),

                // Placeholder for recent products
                // Implement this based on your product data structure
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      "No recent products to display",
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build order status items
  Widget _buildOrderStatusItem(
      String title, int count, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
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
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build quick action buttons
  Widget _buildQuickActionButton(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          height: 60.h,
          width: 60.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
