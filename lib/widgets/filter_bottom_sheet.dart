import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/template_provider.dart';
import 'custom_button.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _tempReligion;
  late String _tempOrientation;
  late String _tempPhotoFilter;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TemplateProvider>();
    _tempReligion = provider.selectedReligion;
    _tempOrientation = provider.selectedOrientation;
    _tempPhotoFilter = provider.selectedPhotoFilter;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.champagne,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.goldBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.surfaceDark : AppColors.champagne,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.surfaceDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.primaryGold, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Templates',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempReligion = 'All';
                    _tempOrientation = 'All';
                    _tempPhotoFilter = 'All';
                  });
                },
                child: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.divider, height: 24),

          // Religion Section
          _buildSectionHeader('Religion / Tradition'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                label: 'All Traditions',
                isSelected: _tempReligion == 'All',
                onTap: () => setState(() => _tempReligion = 'All'),
              ),
              _buildChip(
                label: 'Hindu',
                isSelected: _tempReligion == 'Hindu',
                onTap: () => setState(() => _tempReligion = 'Hindu'),
              ),
              _buildChip(
                label: 'Christian',
                isSelected: _tempReligion == 'Christian',
                onTap: () => setState(() => _tempReligion = 'Christian'),
              ),
              _buildChip(
                label: 'Muslim',
                isSelected: _tempReligion == 'Muslim',
                onTap: () => setState(() => _tempReligion = 'Muslim'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Orientation Section
          _buildSectionHeader('Screen Orientation'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                label: 'All Formats',
                isSelected: _tempOrientation == 'All',
                onTap: () => setState(() => _tempOrientation = 'All'),
              ),
              _buildChip(
                label: '9:16 Vertical (Stories/Reels)',
                icon: Icons.stay_current_portrait,
                isSelected: _tempOrientation == '9:16',
                onTap: () => setState(() => _tempOrientation = '9:16'),
              ),
              _buildChip(
                label: '16:9 Landscape (TV/Screens)',
                icon: Icons.stay_current_landscape,
                isSelected: _tempOrientation == '16:9',
                onTap: () => setState(() => _tempOrientation = '16:9'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Photo Requirement Section
          _buildSectionHeader('Photo Upload Requirement'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                label: 'All',
                isSelected: _tempPhotoFilter == 'All',
                onTap: () => setState(() => _tempPhotoFilter = 'All'),
              ),
              _buildChip(
                label: 'With Photos',
                icon: Icons.add_photo_alternate_outlined,
                isSelected: _tempPhotoFilter == 'With Photo',
                onTap: () => setState(() => _tempPhotoFilter = 'With Photo'),
              ),
              _buildChip(
                label: 'Without Photos (Text-only)',
                icon: Icons.text_snippet_outlined,
                isSelected: _tempPhotoFilter == 'Without Photo',
                onTap: () => setState(() => _tempPhotoFilter = 'Without Photo'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Apply CTA
          CustomButton(
            text: 'Apply Filters',
            onPressed: () {
              context.read<TemplateProvider>().applyFilters(
                    religion: _tempReligion,
                    orientation: _tempOrientation,
                    photoFilter: _tempPhotoFilter,
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
