import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spoil_colors.dart';
import '../../core/theme/spoil_decorations.dart';
import '../auth/providers/auth_provider.dart';
import '../cart/providers/cart_provider.dart';
import '../reminders/models/recipient_model.dart';
import '../reminders/my_people_screen.dart';
import '../reminders/providers/reminders_provider.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/spoil_logo.dart';
import '../catalog/models/category_model.dart';
import '../catalog/providers/catalog_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(catalogHomeProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final auth = ref.watch(authProvider);
    final remindersAsync = auth.isAuthenticated ? ref.watch(inAppRemindersProvider) : null;

    return homeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
      error: (e, _) => _HomeError(onRetry: () => ref.invalidate(catalogHomeProvider)),
      data: (home) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Expanded(child: SpoilLogo(showTagline: true)),
                  if (cartCount > 0)
                    IconButton(
                      onPressed: () => context.push('/cart'),
                      icon: Badge(
                        label: Text('$cartCount'),
                        child: const Icon(Icons.shopping_bag_outlined, color: SpoilColors.teal),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => context.push('/cart'),
                      icon: const Icon(Icons.shopping_bag_outlined, color: SpoilColors.teal),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _HeroBanner(onBrowse: () => context.go('/shop')),
            ),
          ),
          if (remindersAsync != null)
            remindersAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (reminders) {
                if (reminders.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spoils reminders', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...reminders.take(3).map((r) => _InAppReminderCard(reminder: r)),
                      ],
                    ),
                  ),
                );
              },
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text('Shop by category', style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: home.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CategoryTile(category: home.categories[i]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Featured gifts', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(onPressed: () => context.go('/shop'), child: const Text('See all')),
                ],
              ),
            ),
          ),
          if (home.featured.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Run seed_spoil on the backend to populate gifts.'),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: home.featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) => ProductCard(
                    product: home.featured[i],
                    width: 190,
                    compact: true,
                    showFeaturedBadge: true,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text('Popular right now', style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ProductCard(product: home.popular[index]),
                childCount: home.popular.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final CategoryModel category;

  IconData get _icon {
    switch (category.slug) {
      case 'flowers':
        return Icons.local_florist_outlined;
      case 'hampers':
        return Icons.lunch_dining_outlined;
      case 'personalised':
        return Icons.draw_outlined;
      case 'experiences':
        return Icons.celebration_outlined;
      case 'corporate':
        return Icons.business_center_outlined;
      default:
        return Icons.card_giftcard_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SpoilColors.radiusLg),
        onTap: () => context.go('/shop?category=${category.slug}'),
        child: Ink(
          width: 88,
          decoration: SpoilDecorations.card(),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon, color: SpoilColors.teal, size: 28),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SpoilColors.charcoal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: SpoilDecorations.heroGradient,
        borderRadius: BorderRadius.circular(SpoilColors.radiusLg),
        boxShadow: const [
          BoxShadow(color: SpoilColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make someone\'s day',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'Beautiful gifts, delivered with care across South Africa.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.92),
                ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onBrowse,
            child: const Text('Browse gifts'),
          ),
        ],
      ),
    );
  }
}

class _InAppReminderCard extends StatelessWidget {
  const _InAppReminderCard({required this.reminder});

  final InAppReminderModel reminder;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SpoilColors.cream,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.favorite, color: SpoilColors.gold),
        title: Text(reminder.recipientName, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(reminder.message),
        trailing: const Icon(Icons.arrow_forward_rounded, color: SpoilColors.teal),
        onTap: () => context.push(occasionPathForId(reminder.id)),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: SpoilColors.teal),
            const SizedBox(height: 16),
            Text('Couldn\'t load gifts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Start the backend, then run seed_spoil.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}