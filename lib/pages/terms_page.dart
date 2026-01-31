import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Acceptance of Terms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('The following rules and regulations apply to all visitors and users of this app. By accessing the 340 Real Estate Co app, you acknowledge acceptance of these terms and conditions.'),
              SizedBox(height: 16),
              Text('General Disclaimer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('ALL INFORMATION PROVIDED ON THIS WEBSITE IS OFFERED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESSED OR IMPLIED. WE DO NOT WARRANT UNINTERRUPTED ACCESS OR ERROR-FREE CONTENT.'),
              SizedBox(height: 8),
              Text('There may be delays, omissions, interruptions, or inaccuracies in the information available through our website. We disclaim all warranties, including merchantability, fitness for a particular purpose, and non-infringement.'),
              SizedBox(height: 8),
              Text('Under no circumstances shall 340 Real Estate Co be liable for indirect, special, incidental, or consequential damages, including lost profits or data, even if advised of the possibility.'),
              SizedBox(height: 16),
              Text('Accuracy of Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Although we strive to provide accurate information, we make no guarantees regarding completeness, reliability, or timeliness. You access and use the information on this website at your own risk.'),
              SizedBox(height: 16),
              Text('Links to Other Sites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('For your convenience, we may provide links to third-party websites. We do not control or endorse the content of these external sites and are not responsible for their materials or practices.'),
              SizedBox(height: 16),
              Text('Electronic Commerce', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('We offer the ability to purchase goods and services online. While we implement reasonable security precautions, we are not liable for data interception or misuse. You are responsible for the accuracy and legitimacy of the information you provide.'),
              SizedBox(height: 16),
              Text('Limit on Liability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('340 Real Estate Co and its representatives are not liable for incidental or consequential damages arising from the use or inability to use this site. Any claim is limited to the amount paid by you, if any, for using our services.'),
              SizedBox(height: 16),
              Text('Governing Law', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('By using this website, you agree to be governed by the terms set forth herein and applicable local laws.'),
            ],
          ),
        ),
      ),
    );
  }
}
