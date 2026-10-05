import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_service.dart';
import '../../core/constants/app_constants.dart';

class CategoryPickerModal extends StatefulWidget {
  final String initialCategory;

  const CategoryPickerModal({
    super.key,
    required this.initialCategory,
  });

  static Future<String?> show(BuildContext context, {required String initialCategory}) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => CategoryPickerModal(initialCategory: initialCategory),
    );
  }

  @override
  State<CategoryPickerModal> createState() => _CategoryPickerModalState();
}

class _CategoryPickerModalState extends State<CategoryPickerModal> {
  late String _currentSelected;

  static const List<String> applicationCategories = AppConstants.applicationCategories;
  static const List<String> gameCategories = AppConstants.gameCategories;

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.initialCategory;
  }

  bool get _isAllCategories => _currentSelected == 'All Categories';

  bool get _isApplicationsSelected =>
      _currentSelected == 'Applications' ||
      applicationCategories.any((c) => c.toLowerCase() == _currentSelected.toLowerCase());

  bool get _isGamesSelected =>
      _currentSelected == 'Games' ||
      gameCategories.any((c) => c.toLowerCase() == _currentSelected.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 640 ? 580.0 : screenWidth * 0.94;

    final bgColor = isDark ? AppColors.carbon : Colors.white;
    final borderColor = isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? AppColors.paper : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppColors.ash : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Inter',
                            color: primaryTextColor,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Category | ',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: 'Selected: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                            TextSpan(
                              text: _currentSelected,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _isAllCategories
                                    ? AppColors.signalBlue
                                    : (_isGamesSelected ? const Color(0xFFE11D48) : AppColors.signalBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),

              // Content Body (Scrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: All Categories
                      _buildAllCategoriesRow(isDark),
                      const SizedBox(height: 14),

                      // Section 2: Applications
                      _buildApplicationsSection(isDark),
                      const SizedBox(height: 14),

                      // Section 3: Games
                      _buildGamesSection(isDark),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: borderColor),

              // Footer Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTextColor,
                        side: BorderSide(
                          color: isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.signalBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(_currentSelected),
                      child: const Text(
                        'Ok',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllCategoriesRow(bool isDark) {
    final isSelected = _isAllCategories;
    final selectedBg = isDark ? const Color(0xFF0C2B4E) : const Color(0xFFEBF8FF);
    final selectedBorder = isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD);
    final unselectedBorder = isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: () {
        setState(() {
          _currentSelected = 'All Categories';
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? AppColors.signalBlue : (isDark ? AppColors.ash : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 10),
            Text(
              'All Categories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? const Color(0xFF38BDF8) : AppColors.signalBlue)
                    : (isDark ? AppColors.paper : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsSection(bool isDark) {
    final isParentActive = _isApplicationsSelected;
    final borderColor = isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radio Header
          InkWell(
            onTap: () {
              setState(() {
                _currentSelected = 'Applications';
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isParentActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: isParentActive ? AppColors.signalBlue : (isDark ? AppColors.ash : const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Applications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Chips Box with subtle vertical border indicator
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isParentActive ? AppColors.signalBlue.withValues(alpha: 0.3) : borderColor,
                    width: 2,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: applicationCategories.map((cat) {
                  final isChipSelected = _currentSelected.toLowerCase() == cat.toLowerCase();
                  return _buildCategoryChip(
                    label: cat,
                    isSelected: isChipSelected,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _currentSelected = cat;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection(bool isDark) {
    final isParentActive = _isGamesSelected;
    final borderColor = isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.graphite : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radio Header
          InkWell(
            onTap: () {
              setState(() {
                _currentSelected = 'Games';
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isParentActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: isParentActive ? AppColors.signalBlue : (isDark ? AppColors.ash : const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Games',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.paper : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Chips Box
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isParentActive ? AppColors.signalBlue.withValues(alpha: 0.3) : borderColor,
                    width: 2,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gameCategories.map((genre) {
                  final isChipSelected = _currentSelected.toLowerCase() == genre.toLowerCase();
                  return _buildCategoryChip(
                    label: genre,
                    isSelected: isChipSelected,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _currentSelected = genre;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final selectedBg = isDark ? const Color(0xFF0C2B4E) : const Color(0xFFE0F2FE);
    final unselectedBg = isDark ? AppColors.iron : const Color(0xFFF8FAFC);
    final selectedBorder = isDark ? const Color(0xFF0284C7) : AppColors.signalBlue;
    final unselectedBorder = isDark ? AppColors.rekkiBorderSubtle : const Color(0xFFE2E8F0);
    final textColor = isSelected
        ? (isDark ? const Color(0xFF38BDF8) : AppColors.signalBlue)
        : (isDark ? AppColors.ash : const Color(0xFF334155));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
