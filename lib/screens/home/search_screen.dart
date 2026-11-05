import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../providers/template_provider.dart';
import '../../services/api_service.dart';
import '../customization/personalization_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TemplateModel> _allTemplates = [];
  List<TemplateModel> _filteredTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final templates = await ApiService.instance.getTemplates();
      if (mounted) {
        setState(() {
          _allTemplates = templates;
          _filteredTemplates = templates;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allTemplates = [];
          _filteredTemplates = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterTemplates(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredTemplates = List.from(_allTemplates);
      } else {
        _filteredTemplates = _allTemplates.where((t) {
          final titleMatch = t.title.toLowerCase().contains(q);
          final categoryMatch = t.category.toLowerCase().contains(q);
          final religionMatch = t.religion.toLowerCase().contains(q);
          final descMatch = t.description.toLowerCase().contains(q);
          final badgeMatch = t.badgeText.toLowerCase().contains(q);
          final orientationMatch = t.orientation.toLowerCase().contains(q);
          return titleMatch ||
              categoryMatch ||
              religionMatch ||
              descMatch ||
              badgeMatch ||
              orientationMatch;
        }).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterTemplates('');
  }

  void _onSelectTemplate(TemplateModel tmpl) {
    context.read<TemplateProvider>().selectTemplate(tmpl);
    context.read<PersonalizationProvider>().updateTemplate(tmpl);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalizationFormScreen(template: tmpl),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E12),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Search Templates',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Top Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF14141B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryGold,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterTemplates,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      cursorColor: AppColors.primaryGold,
                      decoration: InputDecoration(
                        hintText: 'Search invitation templates...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: _clearSearch,
                      splashRadius: 18,
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),

          // Search Results Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchController.text.trim().isEmpty
                      ? 'All Invitation Templates (${_filteredTemplates.length})'
                      : 'Search Results (${_filteredTemplates.length})',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_searchController.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Text(
                      'Clear',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Templates Grid or Empty State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                    ),
                  )
                : _filteredTemplates.isEmpty
                    ? _buildEmptyState()
                    : _buildTemplatesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF14141B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primaryGold,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No templates found',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any templates matching "${_searchController.text}". Try searching for Wedding, Birthday, Anniversary, or Festivals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Show All Templates',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final tmpl = _filteredTemplates[index];
        final isPremium = tmpl.badgeText.toUpperCase().contains('PRO') ||
            tmpl.badgeText.toUpperCase().contains('PREMIUM') ||
            tmpl.badgeText.toUpperCase().contains('ROYAL');

        return GestureDetector(
          onTap: () => _onSelectTemplate(tmpl),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14141B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPremium
                    ? AppColors.primaryGold.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
                width: isPremium ? 1.2 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Template Thumbnail
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image(
                          image: _resolveImage(tmpl.thumbnailUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: const Color(0xFF1E1E28),
                            child: const Center(
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white38,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Play overlay icon
                      Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                      // Duration Badge (Top Left)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
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
                      ),

                      // Photo slots badge (Top Right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tmpl.hasPhoto
                                ? '${tmpl.photoSlotsCount} Photos'
                                : 'Without Photo',
                            style: GoogleFonts.plusJakartaSans(
                              color: tmpl.hasPhoto
                                  ? const Color(0xFFFF7597)
                                  : AppColors.champagne,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Premium Badge (Bottom Right over thumbnail, only if premium)
                      if (isPremium)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFD4AF37),
                                  Color(0xFFA17A20),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Card Bottom Details
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tmpl.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tmpl.category,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.champagne,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            tmpl.orientation,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Select Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E28),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Customize',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
