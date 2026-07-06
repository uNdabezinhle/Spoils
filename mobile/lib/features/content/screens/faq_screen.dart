import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/spoil_colors.dart';
import '../providers/content_provider.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqsAsync = ref.watch(faqListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: faqsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load FAQs.\n$e'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(faqListProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (faqs) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: faqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final faq = faqs[i];
            return Card(
              child: ExpansionTile(
                title: Text(faq.question, style: Theme.of(context).textTheme.titleMedium),
                iconColor: SpoilColors.teal,
                collapsedIconColor: SpoilColors.teal,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(faq.answer, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}