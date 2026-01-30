import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// Service for sending OTP emails via SMTP.
/// 
/// NOTE: In production, SMTP credentials should be stored securely
/// on a backend server (e.g., Cloud Functions) rather than in the app code.
class EmailService {
  // SMTP Configuration
  static const String _smtpHost = 'premium182.web-hosting.com';
  static const int _smtpPort = 465;
  static const String _smtpUser = 'noreply@340realestate.com';
  static const String _smtpPassword = 'Roud@#159753';

  /// Generates a 6-digit OTP code
  static String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Sends an OTP email to the specified email address.
  /// Returns true if the email was sent successfully.
  Future<bool> sendOtp(String email, String otp) async {
    try {
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        ssl: true,
        username: _smtpUser,
        password: _smtpPassword,
      );

      final message = Message()
        ..from = Address(_smtpUser, EnvConfig.appName)
        ..recipients.add(email)
        ..subject = 'Your Verification Code - ${EnvConfig.appName}'
        ..html = _buildEmailHtml(otp);

      final sendReport = await send(message, smtpServer);
      debugPrint('Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      debugPrint('Error sending OTP email: $e');
      return false;
    }
  }

  /// Builds the HTML content for the OTP email
  String _buildEmailHtml(String otp) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
  <table role="presentation" style="width: 100%; border-collapse: collapse;">
    <tr>
      <td style="padding: 40px 0;">
        <table role="presentation" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center; border-radius: 12px 12px 0 0;">
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">${EnvConfig.appName}</h1>
              <p style="color: rgba(255, 255, 255, 0.9); margin: 10px 0 0; font-size: 14px;">Your trusted property partner</p>
            </td>
          </tr>
          
          <!-- Content -->
          <tr>
            <td style="padding: 40px 30px;">
              <h2 style="color: #333333; margin: 0 0 20px; font-size: 22px; font-weight: 600;">Verification Code</h2>
              <p style="color: #666666; margin: 0 0 30px; font-size: 16px; line-height: 1.6;">
                Use the following code to verify your email address. This code will expire in 10 minutes.
              </p>
              
              <!-- OTP Box -->
              <div style="background-color: #f8f9fa; border: 2px dashed #667eea; border-radius: 8px; padding: 25px; text-align: center; margin: 30px 0;">
                <span style="font-size: 36px; font-weight: 700; color: #667eea; letter-spacing: 8px;">$otp</span>
              </div>
              
              <p style="color: #999999; margin: 30px 0 0; font-size: 14px; line-height: 1.6;">
                If you didn't request this code, please ignore this email. Your account remains secure.
              </p>
            </td>
          </tr>
          
          <!-- Footer -->
          <tr>
            <td style="background-color: #f8f9fa; padding: 25px 30px; text-align: center; border-radius: 0 0 12px 12px;">
              <p style="color: #999999; margin: 0; font-size: 12px;">
                © 2024 ${EnvConfig.appName}. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }
}
