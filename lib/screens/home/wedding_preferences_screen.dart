import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
        return 'Create your royal Half Saree video';
      case 'Wedding':
        return 'Create your royal wedding video';
      case 'Birthday':
        return 'Create your joyful birthday video';
      case 'Housewarming':
        return 'Create your auspicious housewarming video';
      case 'Engagement':
        return 'Create your romantic engagement video';
      case 'AI-Generated Invitations':
        return 'Create your AI-crafted cinematic video';
      default:
        return 'Create your personalized invitation video';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOrientation != null) {
      _selectedOrientation = widget.initialOrientation;
    } else {
      _selectedOrientation = '16:9'; // Default to Horizontal
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

  Widget _buildCheckmark() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE48B), Color(0xFFD4A034), Color(0xFF9E7019)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A034).withValues(alpha: 0.6),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.check, size: 14, color: Color(0xFF160D27)),
      ),
    );
  }

  Widget _buildSectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 1.2,
            ),
            color: const Color(0xFF1B112D),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.cinzel(
                color: const Color(0xFFF3C769),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cinzel(
            color: const Color(0xFFFAF5E4),
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: ORIENTATION CARDS
  // ---------------------------------------------------------------------------
  Widget _buildOrientationCard({
    required String orientation,
    required String title,
    required String assetPath,
    required IconData icon,
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
          height: 146,
          decoration: BoxDecoration(
            color: const Color(0xFF130B24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF3C769)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.2),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF3C769).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  children: [
                    // Phone Preview Mockup
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Bottom Pill Label
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFFE8C169), Color(0xFFBE8A28)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withValues(alpha: 0.04),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected
                                ? const Color(0xFF160D27)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected
                                  ? const Color(0xFF160D27)
                                  : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Gold checkmark at top right
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildCheckmark(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: RELIGION CARDS
  // ---------------------------------------------------------------------------
  Widget _buildReligionCard({
    required String religionKey,
    required String title,
    required String subtitle,
    required String assetPath,
  }) {
    final isSelected = _selectedReligion == religionKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedReligion = religionKey;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 148,
          decoration: BoxDecoration(
            color: const Color(0xFF130B24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF3C769)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.2),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF3C769).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Upper Artwork Illustration
                  Expanded(
                    flex: 10,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Lower Labels
                  Expanded(
                    flex: 5,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF100820),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFE2C98F),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Gold checkmark at top right
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _buildCheckmark(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: PHOTO PREFERENCE CARDS
  // ---------------------------------------------------------------------------
  Widget _buildWithPhotosCard() {
    final isSelected = _selectedPhotoPreference == 'with_photo';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPhotoPreference = 'with_photo';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF130B24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF3C769)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.2),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF3C769).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  // Ornate Golden Framed Couple Portrait
                  Image.asset(
                    'assets/images/photo_couple_frame.png',
                    width: 52,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),

                  // Labels
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'With Photos',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Custom photo &\nanimated reveal',
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFE2C98F),
                            fontSize: 9.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Gold checkmark at top right
              if (isSelected)
                Positioned(
                  top: 2,
                  right: 2,
                  child: _buildCheckmark(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithoutPhotosCard() {
    final isSelected = _selectedPhotoPreference == 'without_photo';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPhotoPreference = 'without_photo';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF130B24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF3C769)
                  : const Color(0xFFD4AF37).withValues(alpha: 0.2),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF3C769).withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  // Typography 'A' Badge
                  Container(
                    width: 48,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF26193E), Color(0xFF150D26)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'A',
                            style: GoogleFonts.cinzel(
                              color: const Color(0xFFF3C769),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            width: 16,
                            height: 1.5,
                            margin: const EdgeInsets.only(top: 1),
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Labels
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Without Photos',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Text, animations\n& music only',
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFE2C98F),
                            fontSize: 9.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Gold checkmark at top right
              if (isSelected)
                Positioned(
                  top: 2,
                  right: 2,
                  child: _buildCheckmark(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0717),
      body: Stack(
        children: [
          // Background Gradient (Deep Imperial Royal Purple/Black)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F081D),
                    Color(0xFF140B25),
                    Color(0xFF0D061A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Bottom Left Decorative Corner Filigree
          Positioned(
            bottom: 0,
            left: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.65,
                child: Image.asset(
                  'assets/images/corner_left.png',
                  width: 95,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Bottom Right Decorative Corner Filigree
          Positioned(
            bottom: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.65,
                child: Image.asset(
                  'assets/images/corner_right.png',
                  width: 95,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Main Responsive Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                // Proportional spacing so everything breathes and fits on one screen
                final double sectionGap = (availableHeight > 720) ? 14.0 : (availableHeight > 640 ? 10.0 : 6.0);
                final double headerGap = (availableHeight > 720) ? 10.0 : 6.0;

                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                    overscroll: false,
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // TOP HEADER
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Back Button at top-left
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B112D).withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_back,
                                            color: Color(0xFFF3C769),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Golden Lotus Motif at top-center
                                  Image.asset(
                                    'assets/images/golden_lotus.png',
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Screen Title
                              Text(
                                _pageTitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cinzel(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  foreground: Paint()
                                    ..shader = const LinearGradient(
                                      colors: [Color(0xFFFFF4D1), Color(0xFFF3C769), Color(0xFFD89F34)],
                                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 320.0, 40.0)),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Subtitle with Decorative Golden Flanking Lines
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFD4AF37).withValues(alpha: 0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      _pageSubtitle,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFE2C98F),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFD4AF37).withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionGap),

                              // SECTION 1: VIDEO ORIENTATION
                              _buildSectionHeader('1', 'Video Orientation'),
                              SizedBox(height: headerGap),
                              Row(
                                children: [
                                  _buildOrientationCard(
                                    orientation: '16:9',
                                    title: 'Horizontal',
                                    assetPath: 'assets/images/wedding_horiz_phone.png',
                                    icon: Icons.crop_landscape_rounded,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildOrientationCard(
                                    orientation: '9:16',
                                    title: 'Vertical',
                                    assetPath: 'assets/images/wedding_vert_phone.png',
                                    icon: Icons.phone_android_rounded,
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionGap),

                              // SECTION 2: RELIGION & STYLE
                              _buildSectionHeader('2', 'Religion & Style'),
                              SizedBox(height: headerGap),
                              Row(
                                children: [
                                  _buildReligionCard(
                                    religionKey: 'Hindu',
                                    title: 'Hindu',
                                    subtitle: 'Mandapam',
                                    assetPath: 'assets/images/religion_hindu.png',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildReligionCard(
                                    religionKey: 'Muslim',
                                    title: 'Muslim',
                                    subtitle: 'Arabic',
                                    assetPath: 'assets/images/religion_muslim.png',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildReligionCard(
                                    religionKey: 'Christian',
                                    title: 'Christian',
                                    subtitle: 'Cathedral',
                                    assetPath: 'assets/images/religion_christian.png',
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionGap),

                              // SECTION 3: PHOTOS
                              _buildSectionHeader('3', 'Photos'),
                              SizedBox(height: headerGap),
                              Row(
                                children: [
                                  _buildWithPhotosCard(),
                                  const SizedBox(width: 10),
                                  _buildWithoutPhotosCard(),
                                ],
                              ),
                            ],
                          ),

                          // BOTTOM CTA BUTTON: "✦ Create Invitation ❯"
                          Padding(
                            padding: EdgeInsets.only(top: sectionGap + 4, bottom: 4),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isReady ? _onViewTemplates : null,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFDE48B),
                                        Color(0xFFE8C169),
                                        Color(0xFFC79224),
                                        Color(0xFF9E7019),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4A034).withValues(alpha: 0.5),
                                        blurRadius: 18,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          '✦',
                                          style: TextStyle(
                                            color: Color(0xFF160D27),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Create Invitation',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: const Color(0xFF160D27),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Color(0xFF160D27),
                                        ),
                                      ],
                                    ),
                                  ),
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
        ],
      ),
    );
  }
}
