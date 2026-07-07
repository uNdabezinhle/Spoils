import 'brand_constants.dart';

abstract final class ApiConstants {
  /// Android emulator loopback to host machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String tagline = BrandConstants.tagline;

  /// WebSocket endpoint for live support chat (JWT passed as query param).
  static String get supportWebSocketUrl {
    final api = Uri.parse(baseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    final port = api.hasPort ? ':${api.port}' : '';
    return '$scheme://${api.host}$port/ws/support/';
  }
}