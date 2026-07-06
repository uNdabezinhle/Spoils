abstract final class ApiConstants {
  /// Android emulator loopback to host machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String tagline = 'Spoil them properly.';
}