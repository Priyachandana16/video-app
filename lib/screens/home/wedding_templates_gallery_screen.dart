import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../providers/template_provider.dart';
import '../../services/api_service.dart';
import '../customization/personalization_form_screen.dart';

class WeddingTemplatesGalleryScreen extends StatefulWidget {
  final String occasion;
  final String orientation; // '16:9' or '9:16'
  final bool hasPhoto;

  const WeddingTemplatesGalleryScreen({
    super.key,
    this.occasion = 'Wedding',
    required this.orientation,
    required this.hasPhoto,
  });

  @override
  State<WeddingTemplatesGalleryScreen> createState() =>
      _WeddingTemplatesGalleryScreenState();
}

class _WeddingTemplatesGalleryScreenState
    extends State<WeddingTemplatesGalleryScreen> {
  late String _currentOrientation;
  late bool _currentHasPhoto;
  List<TemplateModel>? _filteredTemplates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentOrientation = widget.orientation;
    _currentHasPhoto = widget.hasPhoto;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      var templates = await ApiService.instance.getTemplates(
        category: widget.occasion,
        orientation: _currentOrientation,
        hasPhoto: _currentHasPhoto,
      );
      if (templates.isEmpty) {
        templates = await ApiService.instance.getTemplates(
          orientation: _currentOrientation,
          hasPhoto: _currentHasPhoto,
        );
      }
      if (mounted) {
        setState(() {
          _filteredTemplates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filteredTemplates = [];
          _isLoading = false;
        });
      }
    }
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

  Widget _buildPreferenceHeader() {
    final is169 = _currentOrientation == '16:9';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Orientation badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      is169
                          ? Icons.crop_landscape_rounded
                          : Icons.crop_portrait_rounded,
                      size: 13,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      is169 ? 'Horizontal (16:9)' : 'Vertical (9:16)',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.champagne,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Photo preference badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _currentHasPhoto
                      ? AppColors.brandPink.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentHasPhoto
                        ? AppColors.brandPink.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentHasPhoto
                          ? Icons.photo_camera_rounded
                          : Icons.font_download_rounded,
                      size: 12,
                      color: _currentHasPhoto
                          ? AppColors.brandPink
                          : Colors.white70,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currentHasPhoto ? 'With Photo' : 'Without Photo',
                      style: GoogleFonts.plusJakartaSans(
                        color: _currentHasPhoto
                            ? const Color(0xFFFF7597)
                            : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Change preferences button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                Text(
                  'Change',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.tune_rounded,
                  size: 14,
                  color: AppColors.primaryGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(TemplateModel tmpl, bool isHorizontal) {
    final isChroma = tmpl.id.contains('chroma');
    final isGold = tmpl.id.contains('gold');

    return GestureDetector(
      onTap: () => _onSelectTemplate(tmpl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF14141B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isChroma
                ? const Color(0xFF10B981)
                : (isGold
                    ? AppColors.primaryGold
                    : Colors.white.withValues(alpha: 0.12)),
            width: (isChroma || isGold) ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Image Thumbnail with aspect ratio
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
                          child: Icon(Icons.videocam,
                              color: Colors.white38, size: 36),
                        ),
                      ),
                    ),
                  ),

                  // Center Play Overlay
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Top Badges
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Duration Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 11, color: Colors.white),
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

                        // Photo slot badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
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
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Bottom Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tmpl.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tmpl.badgeText,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primaryGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
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
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Customize',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                color: AppColors.champagne,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Matching Templates Found',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We could not find any $_currentOrientation wedding templates ${_currentHasPhoto ? 'with photos' : 'without photos'}. Try choosing a different combination.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Change Preferences',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
    final is169 = _currentOrientation == '16:9';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.occasion == 'Wedding' ? 'Matching Templates' : '${widget.occasion} Templates',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Current Preference summary
            _buildPreferenceHeader(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                      ),
                    )
                  : (_filteredTemplates == null || _filteredTemplates!.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            itemCount: _filteredTemplates!.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: is169 ? 1 : 2,
                              childAspectRatio: is169 ? 1.35 : 0.62,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (context, index) {
                              final tmpl = _filteredTemplates![index];
                              return _buildTemplateCard(tmpl, is169);
                            },
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
