import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'wedding_templates_gallery_screen.dart';

class WeddingPreferencesScreen extends StatefulWidget {
  final String occasion;
  final String? initialOrientation;
  final bool? initialHasPhoto;

  const WeddingPreferencesScreen({
    super.key,
    this.occasion = 'Wedding',
    this.initialOrientation,
    this.initialHasPhoto,
  });

  @override
  State<WeddingPreferencesScreen> createState() => _WeddingPreferencesScreenState();
}

class _WeddingPreferencesScreenState extends State<WeddingPreferencesScreen> {
  // Step 1: Orientation ('16:9' or '9:16')
  String? _selectedOrientation;

  // Step 2: Photo Preference ('with_photo' or 'without_photo')
  String? _selectedPhotoPreference;

  String get _pageTitle {
    switch (widget.occasion) {
      case 'First Birthday':
        return 'First Birthday Invitation';
      case 'Birthday':
        return 'Birthday Invitation';
      case 'Anniversary':
        return 'Anniversary Invitation';
      case 'Festivals':
      case 'Festival':
        return 'Festival Invitation';
      case 'Wedding':
      default:
        return 'Wedding Invitation';
    }
  }

  String get _pageSubtitle {
    switch (widget.occasion) {
      case 'First Birthday':
        return 'Customize your preferences to find the perfect template design for your little one\'s first birthday celebration.';
      case 'Birthday':
        return 'Customize your preferences to find the perfect template design for your birthday celebration.';
      case 'Anniversary':
        return 'Customize your preferences to find the perfect template design for your milestone wedding anniversary.';
      case 'Festivals':
      case 'Festival':
        return 'Customize your preferences to find the perfect template design for your auspicious festival celebration.';
      case 'Wedding':
      default:
        return 'Customize your preferences to find the perfect template design for your auspicious celebration.';
    }
  }

  String get _withPhotoSubtitle {
    switch (widget.occasion) {
      case 'First Birthday':
        return 'Includes baby, parents & family photo slots integrated into the video';
      case 'Birthday':
        return 'Includes birthday star & celebration photo slots integrated into the video';
      case 'Anniversary':
        return 'Includes couple wedding memories & portrait photo slots integrated into the video';
      case 'Festivals':
      case 'Festival':
        return 'Includes family puja & celebration photo slots integrated into the video';
      case 'Wedding':
      default:
        return 'Includes bride, groom & couple photo slots integrated into the video';
    }
  }

  String get _withoutPhotoSubtitle {
    switch (widget.occasion) {
      case 'First Birthday':
        return 'Playful festive themes, joyful typography & celebratory music without photo slots';
      case 'Birthday':
        return 'Vibrant party themes, stylish typography & upbeat music without photo slots';
      case 'Anniversary':
        return 'Royal gold typography, romantic wishes & celebratory melodies without photo slots';
      case 'Festivals':
      case 'Festival':
        return 'Sacred Vedic shlokas, traditional motifs & divine mantras without photo slots';
      case 'Wedding':
      default:
        return 'Elegant traditional Vedic typography, sacred shlokas & mandapam without photo slots';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOrientation != null) {
      _selectedOrientation = widget.initialOrientation;
    }
    if (widget.initialHasPhoto != null) {
      _selectedPhotoPreference = widget.initialHasPhoto! ? 'with_photo' : 'without_photo';
    }
  }

  bool get _isReady => _selectedOrientation != null && _selectedPhotoPreference != null;

  void _onViewTemplates() {
    if (!_isReady) return;

    final hasPhoto = _selectedPhotoPreference == 'with_photo';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeddingTemplatesGalleryScreen(
          occasion: widget.occasion,
          orientation: _selectedOrientation!,
          hasPhoto: hasPhoto,
        ),
      ),
    );
  }

  Widget _buildStepBadge(String number, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGold, AppColors.deepGold],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationCard({
    required String orientation,
    required String title,
    required String ratioLabel,
    required String description,
    required bool isHorizontal,
  }) {
    final isSelected = _selectedOrientation == orientation;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOrientation = orientation;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E1B26)
                : const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGold
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Orientation Miniature Box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: isHorizontal ? 52 : 32,
                    height: isHorizontal ? 32 : 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGold.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isHorizontal
                            ? Icons.crop_landscape_rounded
                            : Icons.crop_portrait_rounded,
                        size: 18,
                        color: isSelected ? AppColors.primaryGold : Colors.white70,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primaryGold : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.black)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title and ratio badge
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGold.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ratioLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? AppColors.richGold : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreferenceCard({
    required String preferenceKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedPhotoPreference == preferenceKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhotoPreference = preferenceKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E1B26)
              : const Color(0xFF14141B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? accentColor : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          _pageTitle,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle Intro
                    Text(
                      _pageSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // STEP 1: Orientation
                    _buildStepBadge('1', 'Choose Video Orientation'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildOrientationCard(
                          orientation: '16:9',
                          title: 'Horizontal',
                          ratioLabel: '16:9 Landscape',
                          description: 'Optimized for TV, screens, and widescreen video',
                          isHorizontal: true,
                        ),
                        const SizedBox(width: 12),
                        _buildOrientationCard(
                          orientation: '9:16',
                          title: 'Vertical',
                          ratioLabel: '9:16 Portrait',
                          description: 'Perfect for WhatsApp Status, Reels & mobile view',
                          isHorizontal: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // STEP 2: Photo Preference
                    _buildStepBadge('2', 'Choose Photo Preference'),
                    const SizedBox(height: 12),
                    _buildPhotoPreferenceCard(
                      preferenceKey: 'with_photo',
                      title: 'With Photo',
                      subtitle: _withPhotoSubtitle,
                      icon: Icons.add_photo_alternate_rounded,
                      accentColor: AppColors.brandPink,
                    ),
                    const SizedBox(height: 12),
                    _buildPhotoPreferenceCard(
                      preferenceKey: 'without_photo',
                      title: 'Without Photo',
                      subtitle: _withoutPhotoSubtitle,
                      icon: Icons.font_download_rounded,
                      accentColor: AppColors.primaryGold,
                    ),
                    const SizedBox(height: 24),

                    // Selection Feedback Pill
                    if (_isReady)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171720),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: AppColors.primaryGold,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Selected: ${_selectedOrientation == '16:9' ? 'Horizontal (16:9)' : 'Vertical (9:16)'} • ${_selectedPhotoPreference == 'with_photo' ? 'With Photo' : 'Without Photo'}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.champagne,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Sticky View Templates Button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E12),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isReady ? _onViewTemplates : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    disabledBackgroundColor: const Color(0xFF1E1E26),
                    foregroundColor: Colors.black,
                    disabledForegroundColor: const Color(0xFF64748B),
                    elevation: _isReady ? 8 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Templates',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: _isReady ? Colors.black : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
