import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/constants/api_constants.dart';
import '../models/support_models.dart';

class SupportWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _messageController = StreamController<SupportMessageModel>.broadcast();
  final _statusController = StreamController<bool>.broadcast();

  Stream<SupportMessageModel> get messages => _messageController.stream;
  Stream<bool> get connected => _statusController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect({required String accessToken}) async {
    await disconnect();
    final uri = Uri.parse(ApiConstants.supportWebSocketUrl).replace(
      queryParameters: {'token': accessToken},
    );
    try {
      _channel = WebSocketChannel.connect(uri);
      _statusController.add(true);
      _subscription = _channel!.stream.listen(
        _onData,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _handleDisconnect();
      rethrow;
    }
  }

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';
      if (type == 'message') {
        final payload = data['message'] as Map<String, dynamic>?;
        if (payload != null) {
          _messageController.add(SupportMessageModel.fromJson(payload));
        }
      }
    } catch (_) {}
  }

  void sendMessage(String body) {
    _channel?.sink.add(jsonEncode({'body': body}));
  }

  void _handleDisconnect() {
    _statusController.add(false);
    _channel = null;
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _statusController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}