import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/template_provider.dart';
import '../../providers/personalization_provider.dart';
import '../../models/template_model.dart';
import '../../widgets/template_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../customization/template_details_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLang = 'EN';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  void _navigateToDetail(TemplateModel template) {
    context.read<TemplateProvider>().selectTemplate(template);
    context.read<PersonalizationProvider>().updateTemplate(template);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateDetailsScreen(template: template),
      ),
    );
  }

  Widget _buildOccasionChip(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.goldBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.surfaceDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateProvider = context.watch<TemplateProvider>();
    final templates = templateProvider.templates;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Image.asset('assets/my_invitation_logo.png'),
            ),
            const SizedBox(width: 10),
            Text(
              'My Invitation',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedLang = 'EN'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedLang == 'EN' ? AppColors.primaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'EN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedLang == 'EN' ? AppColors.surfaceDark : AppColors.champagne,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedLang = 'తె'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedLang == 'తె' ? AppColors.primaryGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'తె',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedLang == 'తె' ? AppColors.surfaceDark : AppColors.champagne,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Button
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.primaryGold, size: 22),
                onPressed: _openFilterSheet,
              ),
              if (templateProvider.hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.royalCrimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => templateProvider.loadTemplates(),
        color: AppColors.primaryGold,
        backgroundColor: AppColors.surfaceDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.inputBorder, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => templateProvider.setSearchQuery(val),
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search Hindu, Christian, Muslim wedding...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primaryGold, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              templateProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Occasion Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOccasionChip(
                      'All',
                      templateProvider.selectedCategory == 'All',
                      () => templateProvider.setCategory('All'),
                    ),
                    _buildOccasionChip(
                      'Wedding',
                      templateProvider.selectedCategory == 'Wedding',
                      () => templateProvider.setCategory('Wedding'),
                    ),
                    _buildOccasionChip(
                      'Reception',
                      templateProvider.selectedCategory == 'Reception',
                      () => templateProvider.setCategory('Reception'),
                    ),
                    _buildOccasionChip(
                      'Engagement',
                      templateProvider.selectedCategory == 'Engagement',
                      () => templateProvider.setCategory('Engagement'),
                    ),
                    _buildOccasionChip(
                      'Sangeet',
                      templateProvider.selectedCategory == 'Sangeet',
                      () => templateProvider.setCategory('Sangeet'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Religion Quick Toggle Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Traditions',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.champagne,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildReligionBanner(
                      title: 'Hindu',
                      subtitle: 'Shubh Vivah',
                      isSelected: templateProvider.selectedReligion == 'Hindu',
                      onTap: () => templateProvider.setReligion(
                        templateProvider.selectedReligion == 'Hindu' ? 'All' : 'Hindu',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildReligionBanner(
                      title: 'Christian',
                      subtitle: 'Matrimony',
                      isSelected: templateProvider.selectedReligion == 'Christian',
                      onTap: () => templateProvider.setReligion(
                        templateProvider.selectedReligion == 'Christian' ? 'All' : 'Christian',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildReligionBanner(
                      title: 'Muslim',
                      subtitle: 'Nikah Mubarak',
                      isSelected: templateProvider.selectedReligion == 'Muslim',
                      onTap: () => templateProvider.setReligion(
                        templateProvider.selectedReligion == 'Muslim' ? 'All' : 'Muslim',
                      ),
                    ),
                  ),
                ],
              ),
              // Photo Options: With Photo / Without Photo
              // Displayed directly below tradition selection when Wedding -> Hindu or Hindu is selected
              if (templateProvider.selectedReligion == 'Hindu' || templateProvider.selectedPhotoFilter != 'All') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildPhotoOptionCard(
                        title: 'With Photo',
                        subtitle: 'Couple photo included',
                        icon: Icons.photo_camera_outlined,
                        isSelected: templateProvider.selectedPhotoFilter == 'With Photo',
                        onTap: () => templateProvider.setPhotoFilter('With Photo'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPhotoOptionCard(
                        title: 'Without Photo',
                        subtitle: 'Vedic text only',
                        icon: Icons.auto_stories_outlined,
                        isSelected: templateProvider.selectedPhotoFilter == 'Without Photo',
                        onTap: () => templateProvider.setPhotoFilter('Without Photo'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Featured Spotlight Video Banner
              if (templates.isNotEmpty) ...[
                Text(
                  'Featured Invitation',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _navigateToDetail(templates.first),
                  child: Container(
                    height: 210,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primaryGold, width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage('assets/candidate_chatgpt_jun.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'MASTER TEMPLATE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.surfaceDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.goldBorder, width: 0.8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 12, color: AppColors.champagne),
                                    const SizedBox(width: 4),
                                    Text(
                                      '0:12s • 9:16',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.champagne,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Royal Mandapam Vivaham',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kundan gold mandap with floating bokeh & circular photo',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppColors.champagne,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryGold,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryGold.withOpacity(0.5),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.surfaceDark,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Templates Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Video Templates',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${templates.length} Available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (templateProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primaryGold),
                  ),
                )
              else if (templates.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.filter_alt_off_outlined, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No templates match this filter',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => templateProvider.resetFilters(),
                          child: const Text('Reset Filters', style: TextStyle(color: AppColors.primaryGold)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tmpl = templates[index];
                    return TemplateCard(
                      template: tmpl,
                      onTap: () => _navigateToDetail(tmpl),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReligionBanner({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold.withOpacity(0.18) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.goldBorder,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primaryGold : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: isSelected ? AppColors.champagne : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold.withOpacity(0.16) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.goldBorder,
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGold.withOpacity(0.25) : AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGold : AppColors.goldBorder.withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryGold : AppColors.champagne,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primaryGold : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primaryGold),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isSelected ? AppColors.champagne : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
