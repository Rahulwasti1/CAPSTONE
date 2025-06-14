import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capstone/widget/user_appbar.dart';

class InfoAppScreen extends StatelessWidget {
  const InfoAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: 'App Information'),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'About AR Fashion',
                      content:
                          'AR Fashion is a revolutionary virtual try-on application that transforms the way you shop for fashion. Using cutting-edge augmented reality technology, you can virtually try on sunglasses, watches, jewelry, and other accessories in real-time using your device\'s camera. Experience the future of fashion shopping with our immersive AR technology.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Key Features',
                      content:
                          '• Real-time AR Try-On Experience\n• Virtual Sunglasses Fitting\n• AR Watch Try-On\n• Jewelry & Ornament Visualization\n• Secure Payment Gateway\n• User Profile Management\n• Wishlist & Favorites\n• Product Search & Categories\n• Dark/Light Theme Support\n• High-Quality Product Images\n• Detailed Product Information\n• Customer Reviews & Ratings',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Technology Stack',
                      content:
                          '• Flutter Framework\n• Firebase Backend\n• Google ML Kit for AR\n• Real-time Face Detection\n• Pose Detection Technology\n• Cloud Storage Integration\n• Advanced Image Processing',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Version Information',
                      content:
                          'Version 1.0.0\nBuild Number: 1\nLast Updated: December 2024\nCompatible with iOS 12.0+ and Android 7.0+',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Contact & Support',
                      content:
                          'Customer Support: support@arfashion.com\nTechnical Support: tech@arfashion.com\nBusiness Inquiries: business@arfashion.com\nPhone: +977-9876543210\nWhatsApp: +977-9876543210\nAddress: Kathmandu, Nepal\n\nSupport Hours:\nMonday - Friday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 4:00 PM\nSunday: Closed',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Development Team',
                      content:
                          'Developed by Team AR Fashion\nBachelor in Computer Engineering\nFinal Year Capstone Project 2024\n\nSpecial thanks to our mentors and the open-source community for making this project possible.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Acknowledgments',
                      content:
                          '• Google ML Kit for AR capabilities\n• Firebase for backend services\n• Flutter community for resources\n• Beta testers for valuable feedback\n• All users who make AR Fashion possible',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
