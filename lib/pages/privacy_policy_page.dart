import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Who We Are', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Our website address is https://340realestateco.com/. This privacy policy explains how your Personally Identifiable Information (PII) is collected and used.'),
              SizedBox(height: 16),
              Text('What Data We Collect and Why', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We may collect your name, email address, or other details when you register, place an order, or contact us—especially via email.'),
              SizedBox(height: 16),
              Text('How We Use Your Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We use your information to respond to inquiries, provide services, follow up on conversations, and improve your experience.'),
              SizedBox(height: 16),
              Text('Data Protection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We use regular Malware Scanning, SSL encryption, and secure networks. Sensitive data is processed via third-party gateways and not stored on our servers.'),
              SizedBox(height: 16),
              Text('Cookies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We do not use cookies for tracking purposes. You can manage cookie settings via your browser.'),
              SizedBox(height: 16),
              Text('Third-Party Disclosure', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We do not sell or trade your information. Trusted third parties may assist in operating our website under strict confidentiality.'),
              SizedBox(height: 16),
              Text('Third-Party Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Our website may link to third-party services. These have separate privacy policies and we are not responsible for their content.'),
              SizedBox(height: 16),
              Text('Google & Advertising', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We use Google AdSense. Google uses DART cookies to serve ads based on your visits. You may opt out through Google\'s Ad Settings.'),
              SizedBox(height: 16),
              Text('California Privacy Rights (CalOPPA)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We comply with CalOPPA: you can visit anonymously and review this policy from our homepage. You’ll be notified of changes on this page.'),
              SizedBox(height: 16),
              Text('Do Not Track Signals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We honor Do Not Track (DNT) settings and do not use tracking when DNT is enabled.'),
              SizedBox(height: 16),
              Text('Children’s Privacy (COPPA)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We do not knowingly market to children under 13 years of age.'),
              SizedBox(height: 16),
              Text('Fair Information Practices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('If a data breach occurs, we’ll notify users within 7 business days via email and on-site notification.'),
              SizedBox(height: 16),
              Text('CAN-SPAM Compliance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We only send emails with user consent and offer easy opt-out options. You can unsubscribe at any time by emailing us.'),
              SizedBox(height: 16),
              Text('Contacting Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Website: https://340realestateco.com/\nAddress: PO Box 766, ST JOHN VI 00831\nEmail: 340realestateco@gmail.com\nLast Updated: July 11, 2018'),
            ],
          ),
        ),
      ),
    );
  }
}
