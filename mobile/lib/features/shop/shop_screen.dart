import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/spoil_colors.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/product_card.dart';
import '../catalog/data/catalog_repository.dart';
import '../catalog/providers/catalog_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  String? _pricePreset;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      Future.microtask(() {
        ref.read(productFiltersProvider.notifier).state = ProductFilters(
          categorySlug: widget.initialCategory,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    ref.read(productFiltersProvider.notifier).state =
        ref.read(productFiltersProvider).copyWith(search: value);
  }

  void _selectCategory(String? slug) {
    ref.read(productFiltersProvider.notifier).state = ref.read(productFiltersProvider).copyWith(
          categorySlug: slug,
          clearCategory: slug == null,
        );
  }

  void _selectPricePreset(String? preset) {
    setState(() => _pricePreset = preset);
    if (preset == null) {
      ref.read(productFiltersProvider.notifier).state = ref.read(productFiltersProvider).copyWith(
            clearMinPrice: true,
            clearMaxPrice: true,
          );
      return;
    }
    double? min;
    double? max;
    switch (preset) {
      case 'under500':
        max = 500;
        break;
      case '500-1000':
        min = 500;
        max = 1000;
        break;
      case 'over1000':
        min = 1000;
        break;
    }
    ref.read(productFiltersProvider.notifier).state = ref.read(productFiltersProvider).copyWith(
          minPrice: min,
          maxPrice: max,
          clearMinPrice: min == null,
          clearMaxPrice: max == null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final filters = ref.watch(productFiltersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shop gifts', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 4),
              Text('Go on, spoil them.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search gifts…',
                  prefixIcon: const Icon(Icons.search, color: SpoilColors.teal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _applySearch(_searchController.text.trim()),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _applySearch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          loading: () => const SizedBox(height: 44),
          error: (_, __) => const SizedBox.shrink(),
          data: (categories) => SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                AllCategoriesChip(
                  selected: filters.categorySlug == null,
                  onTap: () => _selectCategory(null),
                ),
                ...categories.map(
                  (c) => CategoryChip(
                    category: c,
                    selected: filters.categorySlug == c.slug,
                    onTap: () => _selectCategory(c.slug),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _PriceChip(label: 'All prices', selected: _pricePreset == null, onTap: () => _selectPricePreset(null)),
              _PriceChip(label: 'Under R500', selected: _pricePreset == 'under500', onTap: () => _selectPricePreset('under500')),
              _PriceChip(label: 'R500–R1000', selected: _pricePreset == '500-1000', onTap: () => _selectPricePreset('500-1000')),
              _PriceChip(label: 'Over R1000', selected: _pricePreset == 'over1000', onTap: () => _selectPricePreset('over1000')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
            error: (e, _) => Center(child: Text('Could not load products.\n$e', textAlign: TextAlign.center)),
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No gifts match your filters.\nTry adjusting your search.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => ProductCard(product: products[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: SpoilColors.blush,
      ),
    );
  }
}