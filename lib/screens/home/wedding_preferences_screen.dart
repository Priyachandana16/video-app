import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/personalization_provider.dart';
import 'wedding_templates_gallery_screen.dart';

class WeddingPreferencesScreen extends StatefulWidget {
  final String occasion;
  final String? initialOrientation;
  final String? initialReligion;
  final bool? initialHasPhoto;

  const WeddingPreferencesScreen({
    super.key,
    this.occasion = 'Wedding',
    this.initialOrientation,
    this.initialReligion,
    this.initialHasPhoto,
  });

  @override
  State<WeddingPreferencesScreen> createState() => _WeddingPreferencesScreenState();
}

class _WeddingPreferencesScreenState extends State<WeddingPreferencesScreen> {
  // Step 1: Orientation ('16:9' or '9:16')
  String? _selectedOrientation;

  // Step 2: Religion ('Hindu', 'Muslim', 'Christian')
  String? _selectedReligion = 'Hindu';

  // Step 3: Photo Preference ('with_photo' or 'without_photo')
  String? _selectedPhotoPreference = 'with_photo';

  String get _pageTitle {
    switch (widget.occasion) {
      case 'Half Saree Ceremony':
        return 'Half Saree Ceremony';
      case 'Wedding':
        return 'Wedding Invitation';
      case 'Birthday':
        return 'Birthday Invitation';
      case 'Housewarming':
        return 'Housewarming Invitation';
      case 'Engagement':
        return 'Engagement Invitation';
      case 'AI-Generated Invitations':
        return 'AI-Generated Invitations';
      default:
        return '${widget.occasion} Invitation';
    }
  }

  String get _pageSubtitle {
    switch (widget.occasion) {
      case 'Half Saree Ceremony':
        return 'Select your preferred video orientation and religious traditions for your auspicious Half Saree (Langa Voni) celebration.';
      case 'Wedding':
        return 'Select your preferred video orientation and religious traditions to discover handcrafted royal wedding templates.';
      case 'Birthday':
        return 'Choose your video orientation and theme to design a vibrant, joyful birthday invitation.';
      case 'Housewarming':
        return 'Select your video orientation and traditions to create an auspicious Gruhapravesham video.';
      case 'Engagement':
        return 'Select your video orientation and traditions to create a romantic Ring Ceremony invitation.';
      case 'AI-Generated Invitations':
        return 'Choose your video orientation and religious traditions to synthesize AI-crafted cinematic video invitations.';
      default:
        return 'Select your preferred video orientation and religious traditions to discover personalized templates.';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOrientation != null) {
      _selectedOrientation = widget.initialOrientation;
    } else {
      _selectedOrientation = '16:9'; // Default to Horizontal 16:9
    }

    if (widget.initialReligion != null) {
      _selectedReligion = widget.initialReligion;
    }

    if (widget.initialHasPhoto != null) {
      _selectedPhotoPreference = widget.initialHasPhoto! ? 'with_photo' : 'without_photo';
    }
  }

  bool get _isReady =>
      _selectedOrientation != null &&
      _selectedReligion != null &&
      _selectedPhotoPreference != null;

  void _onViewTemplates() {
    if (!_isReady) return;

    final hasPhoto = _selectedPhotoPreference == 'with_photo';
    context.read<PersonalizationProvider>().setPhotoPreference(hasPhoto);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeddingTemplatesGalleryScreen(
          occasion: widget.occasion,
          orientation: _selectedOrientation!,
          religion: _selectedReligion!,
          hasPhoto: hasPhoto,
        ),
      ),
    );
  }

  Widget _buildStepBadge(String number, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGold, AppColors.deepGold],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E1B26) : const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
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
                    width: isHorizontal ? 40 : 26,
                    height: isHorizontal ? 26 : 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGold.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isHorizontal
                            ? Icons.crop_landscape_rounded
                            : Icons.crop_portrait_rounded,
                        size: 15,
                        color: isSelected ? AppColors.primaryGold : Colors.white70,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primaryGold : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.black)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryGold.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ratioLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? AppColors.richGold : const Color(0xFF94A3B8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReligionCard({
    required String religionKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedReligion == religionKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReligion = religionKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B26) : const Color(0xFF14141B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
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
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
          ],
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B26) : const Color(0xFF14141B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
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
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            // Proportional vertical spacing so content fills the page naturally
            final double sectionGap = (availableHeight > 720) ? 14.0 : (availableHeight > 640 ? 10.0 : 6.0);
            final double stepHeaderGap = (availableHeight > 720) ? 9.0 : 6.0;

            return ScrollConfiguration(
              // Completely suppress scrollbar on all platforms
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                overscroll: false,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle Intro
                          Text(
                            _pageSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: sectionGap),

                          // STEP 1: Video Orientation
                          _buildStepBadge('1', 'Choose Video Orientation'),
                          SizedBox(height: stepHeaderGap),
                          Row(
                            children: [
                              _buildOrientationCard(
                                orientation: '16:9',
                                title: 'Horizontal',
                                ratioLabel: '16:9 Landscape',
                                description: 'Optimized for TV, screens & widescreen video',
                                isHorizontal: true,
                              ),
                              const SizedBox(width: 10),
                              _buildOrientationCard(
                                orientation: '9:16',
                                title: 'Vertical',
                                ratioLabel: '9:16 Portrait',
                                description: 'Perfect for WhatsApp Status, Stories & Reels',
                                isHorizontal: false,
                              ),
                            ],
                          ),
                          SizedBox(height: sectionGap),

                          // STEP 2: Religion Selection
                          _buildStepBadge('2', 'Select Religion & Design Style'),
                          SizedBox(height: stepHeaderGap),
                          _buildReligionCard(
                            religionKey: 'Hindu',
                            title: 'Hindu',
                            subtitle: 'Traditional Vedic motifs, sacred shlokas, diya lamps & golden mandapam',
                            icon: Icons.temple_hindu_rounded,
                            accentColor: AppColors.primaryGold,
                          ),
                          _buildReligionCard(
                            religionKey: 'Muslim',
                            title: 'Muslim',
                            subtitle: 'Bismillah invocation, royal Nikah Mubarak, crescent & Arabic calligraphy',
                            icon: Icons.mosque_rounded,
                            accentColor: const Color(0xFF10B981),
                          ),
                          _buildReligionCard(
                            religionKey: 'Christian',
                            title: 'Christian',
                            subtitle: 'Holy Matrimony, cathedral bells, Bible scripture verses & floral cross',
                            icon: Icons.church_rounded,
                            accentColor: const Color(0xFF60A5FA),
                          ),
                          SizedBox(height: sectionGap),

                          // STEP 3: Photo Slots Preference
                          _buildStepBadge('3', 'Photo Preference'),
                          SizedBox(height: stepHeaderGap),
                          _buildPhotoPreferenceCard(
                            preferenceKey: 'with_photo',
                            title: 'With Photos',
                            subtitle: 'Includes customizable photo placeholders with animated reveals',
                            icon: Icons.add_photo_alternate_rounded,
                            accentColor: AppColors.brandPink,
                          ),
                          _buildPhotoPreferenceCard(
                            preferenceKey: 'without_photo',
                            title: 'Without Photos (Text & Video Only)',
                            subtitle: 'Pure royal typography, sacred animations, and ceremonial music',
                            icon: Icons.font_download_rounded,
                            accentColor: AppColors.champagne,
                          ),
                          SizedBox(height: stepHeaderGap),

                          // Selection Feedback Pill
                          if (_isReady)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171720),
                                borderRadius: BorderRadius.circular(10),
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
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Selected: ${_selectedOrientation == '16:9' ? 'Horizontal (16:9)' : 'Vertical (9:16)'} • $_selectedReligion • ${_selectedPhotoPreference == 'with_photo' ? 'With Photo' : 'Without Photo'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.champagne,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Bottom Sticky View Templates Button integrated seamlessly
                      Padding(
                        padding: EdgeInsets.only(top: sectionGap, bottom: 4),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isReady ? _onViewTemplates : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              disabledBackgroundColor: const Color(0xFF1E1E26),
                              foregroundColor: Colors.black,
                              disabledForegroundColor: const Color(0xFF64748B),
                              elevation: _isReady ? 6 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
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
                                    letterSpacing: 0.3,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
