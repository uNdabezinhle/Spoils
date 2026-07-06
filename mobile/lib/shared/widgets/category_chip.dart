import 'package:flutter/material.dart';

import '../../core/theme/spoil_colors.dart';
import '../../features/catalog/models/category_model.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category.name),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: SpoilColors.blush,
        checkmarkColor: SpoilColors.teal,
        labelStyle: TextStyle(
          color: selected ? SpoilColors.teal : SpoilColors.charcoal,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(color: selected ? SpoilColors.teal : SpoilColors.blush),
      ),
    );
  }
}

class AllCategoriesChip extends StatelessWidget {
  const AllCategoriesChip({super.key, required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: const Text('All'),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: SpoilColors.blush,
        checkmarkColor: SpoilColors.teal,
      ),
    );
  }
}