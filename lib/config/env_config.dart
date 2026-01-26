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
