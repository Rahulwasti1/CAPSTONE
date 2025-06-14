import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capstone/widget/user_appbar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: 'Privacy Policy'),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Information We Collect',
                      content:
                          'We collect information that you provide directly to us, including:\n\n• Personal Information: Name, email address, phone number\n• Profile Information: Profile pictures, preferences, settings\n• Device Information: Device type, operating system, unique identifiers\n• Camera Access: Required for AR try-on features (processed locally)\n• Location Data: General location for shipping and regional content\n• Payment Information: Billing details, transaction history\n• Usage Data: App interactions, feature usage, session duration\n• Shopping Data: Purchase history, wishlist, browsing behavior',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'How We Use Your Information',
                      content:
                          '• Provide AR try-on services and app functionality\n• Process orders, payments, and deliver products\n• Personalize your shopping experience and recommendations\n• Communicate about orders, updates, and customer service\n• Send promotional content (with your explicit consent)\n• Improve app performance and user experience\n• Ensure platform security and prevent fraud\n• Comply with legal obligations and resolve disputes\n• Analyze usage patterns for product development',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Data Security & Protection',
                      content:
                          'We implement industry-standard security measures:\n\n• End-to-end encryption for sensitive data\n• Secure Firebase backend with authentication\n• Regular security audits and updates\n• Limited access to personal information\n• Secure payment processing through trusted providers\n• Data backup and recovery procedures\n• Incident response and breach notification protocols',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Camera & AR Privacy',
                      content:
                          'Your privacy during AR experiences:\n\n• Camera access is only used for AR try-on features\n• No video or images are stored on our servers\n• All AR processing happens locally on your device\n• Camera feed is never transmitted or shared\n• You can revoke camera permissions anytime\n• AR data is not used for facial recognition or identification\n• No biometric data is collected or stored',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Data Sharing & Third Parties',
                      content:
                          'We may share your information with:\n\n• Payment processors for transaction processing\n• Shipping partners for order delivery\n• Analytics services for app improvement (anonymized data)\n• Legal authorities when required by law\n• Service providers who assist our operations\n\nWe never sell your personal information to third parties.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Your Privacy Rights',
                      content:
                          'You have the right to:\n\n• Access and review your personal data\n• Correct or update inaccurate information\n• Request deletion of your account and data\n• Export your data in a portable format\n• Withdraw consent for marketing communications\n• Object to certain data processing activities\n• Lodge complaints with data protection authorities\n• Request information about data sharing',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Data Retention',
                      content:
                          'We retain your information for as long as:\n\n• Your account remains active\n• Required for providing our services\n• Necessary for legal compliance\n• Needed for legitimate business purposes\n\nDeleted data is permanently removed within 30 days.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Children\'s Privacy',
                      content:
                          'Our service is not intended for children under 13. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'International Data Transfers',
                      content:
                          'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data during international transfers.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Policy Updates',
                      content:
                          'We may update this privacy policy periodically. We will notify you of significant changes through:\n\n• In-app notifications\n• Email notifications\n• Updated policy posting\n\nContinued use after changes constitutes acceptance.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Contact Information',
                      content:
                          'For privacy-related questions or concerns:\n\nPrivacy Officer: privacy@arfashion.com\nData Protection: dataprotection@arfashion.com\nGeneral Support: support@arfashion.com\nPhone: +977-9876543210\n\nMailing Address:\nAR Fashion Privacy Team\nKathmandu, Nepal\n\nResponse Time: Within 72 hours',
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
