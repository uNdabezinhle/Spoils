import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/spoil_colors.dart';
import '../../shared/widgets/spoil_logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SpoilLogo(showTagline: true),
                const SizedBox(height: 24),
                _HeroBanner(),
                const SizedBox(height: 28),
                Text('Featured gifts', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Thoughtfully curated — go on, spoil them.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _FeaturedCard(index: index),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: _ApiStatusCard(),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SpoilColors.teal, Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make someone\'s day',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Beautiful gifts, delivered with care across South Africa.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: SpoilColors.gold, foregroundColor: SpoilColors.charcoal),
            child: const Text('Browse gifts'),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.index});

  final int index;

  static const _titles = ['Spring Bloom', 'Luxury Hamper', 'Personalised Mug', 'Spa Experience'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 160,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: SpoilColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.card_giftcard, color: SpoilColors.teal, size: 36)),
              ),
              const Spacer(),
              Text(_titles[index], style: Theme.of(context).textTheme.titleMedium),
              Text('From R${(299 + index * 150)}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApiStatusCard extends ConsumerStatefulWidget {
  const _ApiStatusCard();

  @override
  ConsumerState<_ApiStatusCard> createState() => _ApiStatusCardState();
}

class _ApiStatusCardState extends ConsumerState<_ApiStatusCard> {
  String _status = 'Checking connection…';
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final dio = ref.read(apiClientProvider);
      final healthUrl = dio.options.baseUrl.replaceFirst('/api/v1', '/api/health/');
      final response = await dio.get(healthUrl);
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _ok = data['status'] == 'ok';
        _status = _ok ? 'API connected — ${data['tagline']}' : 'API unreachable';
      });
    } catch (_) {
      setState(() {
        _ok = false;
        _status = 'Start the backend with docker compose up';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_ok ? Icons.check_circle : Icons.cloud_off, color: _ok ? SpoilColors.teal : Colors.orange),
        title: const Text('Backend status'),
        subtitle: Text(_status),
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _checkHealth),
      ),
    );
  }
}