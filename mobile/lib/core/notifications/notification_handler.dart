import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Background push: ${message.data}');
  }
}

class NotificationHandler {
  NotificationHandler({required GoRouter router}) : _router = router;

  final GoRouter _router;

  Future<void> initialize() async {
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _navigateFromData(initial.data);
    }
  }

  void _handleForeground(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Foreground push: ${message.notification?.title} — ${message.data}');
    }
  }

  void _handleOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'auto_gift_approval') {
      final occasionId = data['occasion_id']?.toString();
      if (occasionId != null) {
        _router.go('/people/occasion/$occasionId');
      }
      return;
    }
    if (type == 'order_status') {
      final orderId = data['order_id']?.toString();
      if (orderId != null) {
        _router.go('/orders/$orderId');
      }
    }
  }
}

final notificationHandlerProvider = Provider<NotificationHandler>((ref) {
  return NotificationHandler(router: ref.watch(routerProvider));
});