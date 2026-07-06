import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/spoil_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SpoilApp()));
}

class SpoilApp extends ConsumerWidget {
  const SpoilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Spoil',
      debugShowCheckedModeBanner: false,
      theme: SpoilTheme.light,
      routerConfig: router,
    );
  }
}