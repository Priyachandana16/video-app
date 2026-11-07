import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/template_provider.dart';
import '../../providers/personalization_provider.dart';
import '../../models/template_model.dart';
import '../customization/personalization_form_screen.dart';
import '../auth/sign_in_screen.dart';
import 'wedding_preferences_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _selectedOccasion = 'Wedding';

  final List<Map<String, dynamic>> _occasions = [
    {
      'title': 'Half Saree Ceremony',
      'count': '35+ designs',
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF381B2E), // Rich Violet / Saree Silk
      'borderColor': const Color(0xFFE879F9),
    },
    {
      'title': 'Wedding',
      'count': '100+ designs',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFF481622), // Burgundy / Wine
      'borderColor': const Color(0xFFFF5277),
    },
    {
      'title': 'Birthday',
      'count': '45+ designs',
      'icon': Icons.celebration_rounded,
      'color': const Color(0xFF1C476E), // Ocean Blue
      'borderColor': const Color(0xFF60A5FA),
    },
    {
      'title': 'Housewarming',
      'count': '30+ designs',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF382312), // Bronze / Warm Diya
      'borderColor': const Color(0xFFFBBF24),
    },
    {
      'title': 'Engagement',
      'count': '40+ designs',
      'icon': Icons.diamond_rounded,
      'color': const Color(0xFF1D3328), // Emerald / Jade
      'borderColor': const Color(0xFF34D399),
    },
    {
      'title': 'AI-Generated Invitations',
      'count': 'AI Magic',
      'icon': Icons.psychology_alt_rounded,
      'color': const Color(0xFF26183D), // Deep Purple / Galaxy
      'borderColor': const Color(0xFFA78BFA),
    },
  ];

  void _navigateToCustomize(TemplateModel template) {
    context.read<TemplateProvider>().selectTemplate(template);
    context.read<PersonalizationProvider>().updateTemplate(template);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalizationFormScreen(template: template),
      ),
    );
  }

  void _navigateToWeddingCategory() {
    _navigateToOccasionPreferences('Wedding');
  }

  void _navigateToOccasionPreferences(String occasion) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeddingPreferencesScreen(occasion: occasion),
      ),
    );
  }

  ImageProvider _resolveImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    if (url.startsWith('/assets/')) {
      return NetworkImage('http://localhost:5000$url');
    }
    return AssetImage(url);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildOccasionGridCard(Map<String, dynamic> occ) {
    final occasionTitle = occ['title'] as String;
    final isWedding = occasionTitle == 'Wedding';
    final isSelected = _selectedOccasion == occasionTitle;
    final Color bg = occ['color'] as Color;
    final Color border = occ['borderColor'] as Color;

    return GestureDetector(
      onTap: () => _navigateToOccasionPreferences(occasionTitle),
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (isWedding || isSelected) ? border : Colors.white.withValues(alpha: 0.08),
            width: (isWedding || isSelected) ? 1.5 : 1,
          ),
          boxShadow: isWedding
              ? [
                  BoxShadow(
                    color: border.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              occ['icon'] as IconData,
              color: Colors.white,
              size: 26,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occ['title'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  occ['count'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTemplateGridCard(TemplateModel tmpl) {
    final isChroma = tmpl.id.contains('chroma');
    final isGold = tmpl.id.contains('gold');

    return GestureDetector(
      onTap: () => _navigateToCustomize(tmpl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16161C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isChroma
                ? const Color(0xFF10B981)
                : (isGold ? const Color(0xFFEAB308) : Colors.white.withValues(alpha: 0.1)),
            width: (isChroma || isGold) ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isChroma
                  ? const Color(0x3310B981)
                  : (isGold ? const Color(0x33EAB308) : Colors.black.withValues(alpha: 0.4)),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Thumbnail Poster
            Positioned.fill(
              child: Image(
                image: _resolveImage(tmpl.thumbnailUrl),
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: const Color(0xFF1F1F28),
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white38, size: 40),
                  ),
                ),
              ),
            ),

            // Top Badges Row (Screenshot 6 Layout)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Duration & Photos Badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(tmpl.durationSeconds),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tmpl.photoSlotsCount} photos',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // AI / Premium Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: isGold
                          ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                          : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isGold ? 'PREMIUM' : 'AI',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Gradient Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 36, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tmpl.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tmpl.badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        color: isChroma ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateProvider = context.watch<TemplateProvider>();
    final templates = templateProvider.templates;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Header Bar with Official My Invitation Logo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Official Logo with Telugu Tagline intact
                    Container(
                      height: 48,
                      constraints: const BoxConstraints(maxWidth: 190),
                      child: Image.asset(
                        'assets/official_logo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),

                    // Polished Sign In Pill Button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sign in',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Browse by occasion Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse by occasion',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick an occasion to discover handcrafted templates',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2-Column Grid of 5 Occasions Matching Screenshot 3
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildOccasionGridCard(_occasions[index]),
                  childCount: _occasions.length,
                ),
              ),
            ),

            // "View all 10 occasions v"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all categories',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // Section Header: "The Grand Seemantham & Telugu Vivaham" (Screenshot 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Royal Wedding Invitations',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToWeddingCategory,
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFEAB308),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFEAB308), size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2-Column Vertical 9:16 Template Cards Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62, // 9:14.5 for tall portrait cards
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tmpl = templates[index];
                    return _buildTemplateGridCard(tmpl);
                  },
                  childCount: templates.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}
