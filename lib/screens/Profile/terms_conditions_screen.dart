import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:capstone/widget/user_appbar.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            UserAppbar(text: 'Terms & Conditions'),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Acceptance of Terms',
                      content:
                          'By downloading, installing, accessing, or using the AR Fashion mobile application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our service.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Eligibility & Account Registration',
                      content:
                          '• You must be at least 13 years old to use this service\n• Users under 18 require parental consent\n• You must provide accurate and complete information\n• One account per person is allowed\n• You are responsible for maintaining account security\n• Notify us immediately of any unauthorized access\n• We reserve the right to suspend or terminate accounts',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'AR Try-On Technology',
                      content:
                          '• AR features are provided for demonstration purposes\n• Virtual try-on results may vary from actual products\n• We do not guarantee exact color, size, or fit representation\n• Camera access is required for AR functionality\n• AR processing occurs locally on your device\n• No biometric data is collected or stored\n• Results depend on device capabilities and lighting conditions',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Product Information & Availability',
                      content:
                          '• Product descriptions and images are for reference only\n• We strive for accuracy but cannot guarantee perfection\n• Product availability is subject to change\n• Prices are displayed in NPR unless otherwise stated\n• We reserve the right to modify prices without notice\n• Special offers and discounts have specific terms\n• Product specifications may vary from descriptions',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Orders & Payment',
                      content:
                          '• All orders are subject to acceptance and availability\n• Payment must be completed before order processing\n• We accept various payment methods as displayed\n• Payment processing is handled by secure third-party providers\n• Order confirmation will be sent via email\n• We reserve the right to cancel orders for any reason\n• Bulk orders may require special arrangements',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Shipping & Delivery',
                      content:
                          '• Delivery times are estimates and not guaranteed\n• Shipping costs are calculated at checkout\n• Risk of loss transfers upon delivery\n• You must inspect items upon delivery\n• Report any damage or missing items within 24 hours\n• Delivery attempts are limited as per courier policy\n• International shipping may incur additional duties',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Returns, Exchanges & Refunds',
                      content:
                          '• 7-day return policy for unused items in original condition\n• Items must include all original packaging and tags\n• Return shipping costs are borne by the customer\n• Refunds processed within 7-14 business days\n• Exchanges subject to product availability\n• Certain items may be non-returnable (hygiene products)\n• Return authorization required before sending items',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'User Conduct & Prohibited Activities',
                      content:
                          'You agree not to:\n\n• Use the service for illegal purposes\n• Violate any applicable laws or regulations\n• Infringe on intellectual property rights\n• Upload malicious content or viruses\n• Attempt to hack or disrupt the service\n• Create fake accounts or impersonate others\n• Engage in fraudulent activities\n• Spam or send unsolicited communications',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Intellectual Property Rights',
                      content:
                          '• All content is owned by AR Fashion or licensed to us\n• This includes text, images, logos, AR technology, and software\n• You may not copy, reproduce, or distribute our content\n• User-generated content remains your property\n• You grant us license to use your content for service improvement\n• Respect third-party intellectual property rights\n• Report any copyright infringement to us',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Privacy & Data Protection',
                      content:
                          '• Your privacy is important to us\n• Please review our Privacy Policy for details\n• We collect and use data as described in our Privacy Policy\n• You consent to data processing as outlined\n• You can request data deletion or modification\n• We implement security measures to protect your data\n• Third-party services may have their own privacy policies',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Disclaimers & Limitation of Liability',
                      content:
                          '• Service is provided "as is" without warranties\n• We disclaim all warranties, express or implied\n• We are not liable for indirect or consequential damages\n• Our liability is limited to the amount you paid for products\n• We are not responsible for third-party content or services\n• Force majeure events may affect service availability\n• Some jurisdictions may not allow liability limitations',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Indemnification',
                      content:
                          'You agree to indemnify and hold harmless AR Fashion from any claims, damages, or expenses arising from your use of the service, violation of these terms, or infringement of any rights.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Termination',
                      content:
                          '• Either party may terminate this agreement at any time\n• We may suspend or terminate your account for violations\n• Upon termination, your right to use the service ceases\n• Certain provisions survive termination\n• You may delete your account through app settings\n• Outstanding obligations remain after termination',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Governing Law & Dispute Resolution',
                      content:
                          '• These terms are governed by the laws of Nepal\n• Disputes will be resolved through arbitration when possible\n• Legal proceedings must be filed in Kathmandu courts\n• You waive the right to class action lawsuits\n• Informal dispute resolution is encouraged first\n• Some claims may be resolved in small claims court',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Changes to Terms',
                      content:
                          '• We may modify these terms at any time\n• Changes will be posted in the app and on our website\n• Continued use constitutes acceptance of new terms\n• Significant changes will be communicated via email\n• You should review terms periodically\n• Previous versions are archived for reference',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Severability & Entire Agreement',
                      content:
                          '• If any provision is invalid, the rest remains in effect\n• These terms constitute the entire agreement\n• They supersede all previous agreements\n• No waiver of terms unless in writing\n• Headings are for convenience only\n• Terms may be translated but English version controls',
                    ),
                    SizedBox(height: 20.h),
                    _buildSection(
                      title: 'Contact Information',
                      content:
                          'For questions about these Terms & Conditions:\n\nLegal Department: legal@arfashion.com\nCustomer Service: support@arfashion.com\nBusiness Inquiries: business@arfashion.com\nPhone: +977-9876543210\n\nMailing Address:\nAR Fashion Legal Team\nKathmandu, Nepal\n\nLast Updated: December 2024',
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
