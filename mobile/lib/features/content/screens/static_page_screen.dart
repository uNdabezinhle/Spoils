import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/spoil_colors.dart';
import '../providers/content_provider.dart';

class StaticPageScreen extends ConsumerWidget {
  const StaticPageScreen({super.key, required this.pageType});

  final String pageType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(staticPageProvider(pageType));

    return Scaffold(
      appBar: AppBar(
        title: pageAsync.maybeWhen(data: (p) => Text(p.title), orElse: () => const Text('Spoils')),
      ),
      body: pageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Could not load this page.'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(staticPageProvider(pageType)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (page) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SpoilColors.teal),
              ),
              const SizedBox(height: 16),
              Text(
                page.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}