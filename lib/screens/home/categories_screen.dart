import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/personalization_provider.dart';
import '../../models/template_model.dart';
import '../customization/personalization_form_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final String categoryTitle;

  const CategoriesScreen({
    super.key,
    this.categoryTitle = 'Wedding',
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _activeFilter = 'Telugu';

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

  void _navigateToCustomize(TemplateModel tmpl) {
    context.read<TemplateProvider>().selectTemplate(tmpl);
    final pref = context.read<PersonalizationProvider>().userPhotoPreference;
    context.read<PersonalizationProvider>().updateTemplate(tmpl, hasPhoto: pref);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalizationFormScreen(
          template: tmpl,
          hasPhotoPreference: pref,
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, IconData? icon) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.16) : const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(TemplateModel tmpl) {
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
            // Full Height Cover Image
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

            // Top Badges Row Matching Screenshot 6
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
    final templates = context.watch<TemplateProvider>().templates;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.categoryTitle,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '100+ designs',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Filter Chips Row (Screenshot 6)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('Filters', Icons.tune_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill('Photos', Icons.photo_library_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill('English', null),
                    const SizedBox(width: 8),
                    _buildFilterPill('Telugu', null),
                  ],
                ),
              ),
            ),
          ),

          // Header Text: "100+ designs"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: Text(
                '100+ designs',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 2-Column Vertical 9:16 Template Cards Grid (Screenshot 6)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62, // 9:14.5
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tmpl = templates[index];
                  return _buildTemplateCard(tmpl);
                },
                childCount: templates.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 36),
          ),
        ],
      ),
    );
  }
}
