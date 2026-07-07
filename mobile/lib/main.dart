import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/brand_constants.dart';
import 'core/notifications/notification_handler.dart';
import 'core/router/app_router.dart';
import 'core/theme/spoil_theme.dart';

const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (_firebaseProjectId.isNotEmpty && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
        appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
        projectId: _firebaseProjectId,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_firebaseProjectId.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  runApp(const ProviderScope(child: SpoilApp()));
}

class SpoilApp extends ConsumerStatefulWidget {
  const SpoilApp({super.key});

  @override
  ConsumerState<SpoilApp> createState() => _SpoilAppState();
}

class _SpoilAppState extends ConsumerState<SpoilApp> {
  @override
  void initState() {
    super.initState();
    if (_firebaseProjectId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(notificationHandlerProvider).initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: BrandConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: SpoilTheme.light,
      routerConfig: router,
    );
  }
}