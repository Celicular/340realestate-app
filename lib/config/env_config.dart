/// Environment configuration for API keys and sensitive data
///
/// SECURITY NOTE: In production, use flutter_dotenv or --dart-define
/// to inject these values at build time instead of hardcoding.
///
/// For production builds, use:
/// flutter build apk --dart-define=OPENROUTER_API_KEY=your_key_here
///
class EnvConfig {
  // OpenRouter API Configuration
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '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',
  );

  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  // AI Model Configuration
  static const String aiModel = 'mistralai/mistral-small-3.1-24b-instruct:free';

  // App Configuration
  static const String appName = '340 Real Estate';
  static const String appUrl = 'https://340realestate.com';
}
