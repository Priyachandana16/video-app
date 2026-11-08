import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../providers/template_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/video_player_widget.dart';
import '../customization/personalization_form_screen.dart';

class WeddingTemplatesGalleryScreen extends StatefulWidget {
  final String occasion;
  final String orientation; // '16:9' or '9:16'
  final String religion; // 'Hindu', 'Muslim', 'Christian'
  final bool hasPhoto;

  const WeddingTemplatesGalleryScreen({
    super.key,
    this.occasion = 'Wedding',
    required this.orientation,
    this.religion = 'Hindu',
    this.hasPhoto = true,
  });

  @override
  State<WeddingTemplatesGalleryScreen> createState() =>
      _WeddingTemplatesGalleryScreenState();
}

class _WeddingTemplatesGalleryScreenState
    extends State<WeddingTemplatesGalleryScreen> {
  late String _currentOrientation;
  late String _currentReligion;
  late bool _currentHasPhoto;
  List<TemplateModel>? _filteredTemplates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentOrientation = widget.orientation;
    _currentReligion = widget.religion;
    _currentHasPhoto = widget.hasPhoto;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      var templates = await ApiService.instance.getTemplates(
        category: widget.occasion,
        orientation: _currentOrientation,
        religion: _currentReligion,
        hasPhoto: _currentHasPhoto,
      );

      // Only search across occasions with the EXACT same orientation, religion, and hasPhoto preference
      if (templates.isEmpty) {
        templates = await ApiService.instance.getTemplates(
          orientation: _currentOrientation,
          religion: _currentReligion,
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
    context.read<PersonalizationProvider>().updateTemplate(tmpl, hasPhoto: _currentHasPhoto);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalizationFormScreen(
          template: tmpl,
          hasPhotoPreference: _currentHasPhoto,
        ),
      ),
    );
  }

  void _showVideoPreviewDialog(TemplateModel tmpl) {
    final isVertical = tmpl.orientation == '9:16';
    final videoPath = (!tmpl.hasPhoto)
        ? tmpl.masterVideoPath
        : (tmpl.sampleResultPath ?? tmpl.masterVideoPath);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF14141E),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.goldBorder, width: 1.2),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top header: Title and close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tmpl.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tmpl.religion,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.primaryGold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${tmpl.orientation} • ${_formatDuration(tmpl.durationSeconds)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Exact 9:16 (Portrait) or 16:9 (Landscape) Video Player Container
                    Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: isVertical
                              ? (MediaQuery.of(ctx).size.height * 0.56).clamp(320.0, 480.0)
                              : 220,
                          maxWidth: isVertical ? 270 : double.infinity,
                        ),
                        child: AspectRatio(
                          aspectRatio: isVertical ? 9 / 16 : 16 / 9,
                          child: VideoPlayerWidget(
                            videoSource: videoPath,
                            isAsset: true,
                            fit: BoxFit.contain, // Fit complete video inside container, no cropping
                            aspectRatio: isVertical ? 9 / 16 : 16 / 9,
                            autoPlay: true,
                            looping: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      tmpl.description,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _onSelectTemplate(tmpl);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: Text(
                              'Select Template',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active Badges Row
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Orientation badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              is169 ? Icons.crop_landscape_rounded : Icons.crop_portrait_rounded,
                              size: 12,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              is169 ? '16:9 Horizontal' : '9:16 Vertical',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.champagne,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Religion badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.temple_hindu_rounded,
                              size: 12,
                              color: Color(0xFF60A5FA),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentReligion,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF93C5FD),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.occasion,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Photo Preference badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentHasPhoto
                              ? AppColors.brandPink.withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _currentHasPhoto
                                ? AppColors.brandPink.withValues(alpha: 0.4)
                                : const Color(0xFF10B981).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentHasPhoto ? Icons.photo_library_outlined : Icons.font_download_rounded,
                              size: 12,
                              color: _currentHasPhoto ? AppColors.brandPink : const Color(0xFF34D399),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentHasPhoto ? 'With Photos' : 'Without Photos',
                              style: GoogleFonts.plusJakartaSans(
                                color: _currentHasPhoto ? const Color(0xFFFF7597) : const Color(0xFF6EE7B7),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Change Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    Text(
                      'Filter',
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
          const SizedBox(height: 10),

          // Quick Switcher Row: Religion pills + Photo Preference toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: ['Hindu', 'Muslim', 'Christian'].map((rel) {
                  final isSelected = _currentReligion == rel;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentReligion = rel;
                        });
                        _loadTemplates();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryGold : const Color(0xFF1E1E28),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGold : Colors.white12,
                          ),
                        ),
                        child: Text(
                          rel,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Photo Mode Toggle Pill
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentHasPhoto = !_currentHasPhoto;
                  });
                  context.read<PersonalizationProvider>().setPhotoPreference(_currentHasPhoto);
                  _loadTemplates();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentHasPhoto
                        ? AppColors.brandPink.withValues(alpha: 0.15)
                        : const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _currentHasPhoto
                          ? AppColors.brandPink.withValues(alpha: 0.45)
                          : const Color(0xFF10B981).withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentHasPhoto ? Icons.photo_library_outlined : Icons.font_download_rounded,
                        size: 11,
                        color: _currentHasPhoto ? AppColors.brandPink : const Color(0xFF34D399),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentHasPhoto ? 'With Photos' : 'Without Photos',
                        style: GoogleFonts.plusJakartaSans(
                          color: _currentHasPhoto ? const Color(0xFFFF7597) : const Color(0xFF6EE7B7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(TemplateModel tmpl, bool isHorizontal) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
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
                        child: Icon(Icons.videocam, color: Colors.white38, size: 36),
                      ),
                    ),
                  ),
                ),

                // Center Play Button to Preview Video
                Center(
                  child: GestureDetector(
                    onTap: () => _showVideoPreviewDialog(tmpl),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 11, color: Colors.white),
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

                      // Religion badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4), width: 0.8),
                        ),
                        child: Text(
                          tmpl.religion,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.champagne,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Bottom Details & Action Buttons
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
                const SizedBox(height: 10),

                // Dual Buttons: Preview Video & Select Template
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showVideoPreviewDialog(tmpl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E28),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_circle_outline_rounded,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'Preview',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onSelectTemplate(tmpl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Select',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              'We could not find $_currentOrientation templates for $_currentReligion ${widget.occasion}. Try selecting a different religion or orientation.',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          '${widget.occasion} Templates',
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
            // Current Preference summary with quick switcher
            _buildPreferenceHeader(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                      ),
                    )
                  : (_filteredTemplates == null || _filteredTemplates!.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            itemCount: _filteredTemplates!.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: is169 ? 1 : 2,
                              childAspectRatio: is169 ? 1.32 : 0.60,
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
