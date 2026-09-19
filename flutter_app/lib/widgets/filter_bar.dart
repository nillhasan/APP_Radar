import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

class FilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String selectedPlatform;
  final ValueChanged<String> onPlatformChanged;
  final String? selectedSort;
  final ValueChanged<String>? onSortChanged;

  const FilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.selectedPlatform,
    required this.onPlatformChanged,
    this.selectedSort,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final searchField = SizedBox(
      height: 40,
      width: isDesktop ? 260 : double.infinity,
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search apps, features...',
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => onSearchChanged(''),
                )
              : null,
        ),
      ),
    );

    final categoryDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          items: AppConstants.categories.map((c) {
            return DropdownMenuItem(value: c, child: Text(c));
          }).toList(),
          onChanged: (val) {
            if (val != null) onCategoryChanged(val);
          },
        ),
      ),
    );

    final platformDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPlatform,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          items: AppConstants.platforms.map((p) {
            return DropdownMenuItem(value: p, child: Text(p));
          }).toList(),
          onChanged: (val) {
            if (val != null) onPlatformChanged(val);
          },
        ),
      ),
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            searchField,
            const SizedBox(width: 12),
            categoryDropdown,
            const SizedBox(width: 12),
            platformDropdown,
            const Spacer(),
            if (selectedSort != null && onSortChanged != null) ...[
              const Text('Sort by: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 6),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSort,
                    icon: const Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'Opportunity Score', child: Text('Opportunity Score')),
                      DropdownMenuItem(value: 'Growth', child: Text('Growth Velocity')),
                      DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                      DropdownMenuItem(value: 'Reviews', child: Text('Reviews Count')),
                    ],
                    onChanged: (val) {
                      if (val != null) onSortChanged!(val);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Mobile layout
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: categoryDropdown),
              const SizedBox(width: 8),
              Expanded(child: platformDropdown),
            ],
          ),
        ],
      ),
    );
  }
}
