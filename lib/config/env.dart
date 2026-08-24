/// Environment configuration loading secrets via --dart-define.
class Env {
  Env._();

  /// Gemini API Key passed via `--dart-define=GEMINI_API_KEY=your_key`
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Helper getter checking if the Gemini API Key is configured.
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
}
