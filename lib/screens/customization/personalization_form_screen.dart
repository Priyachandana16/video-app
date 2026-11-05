import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'review_details_screen.dart';

class PersonalizationFormScreen extends StatefulWidget {
  final TemplateModel? template;

  const PersonalizationFormScreen({
    super.key,
    this.template,
  });

  @override
  State<PersonalizationFormScreen> createState() => _PersonalizationFormScreenState();
}

class _PersonalizationFormScreenState extends State<PersonalizationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _groomController;
  late TextEditingController _brideController;
  late TextEditingController _ceremonyController;
  late TextEditingController _parentsController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _venueController;
  late TextEditingController _rsvpController;

  TemplateModel _getActiveTemplate() {
    if (widget.template != null) return widget.template!;
    final selected = context.read<TemplateProvider>().selectedTemplate;
    if (selected != null) return selected;
    return context.read<TemplateProvider>().templates.first;
  }

  @override
  void initState() {
    super.initState();
    final p = context.read<PersonalizationProvider>().data;

    _groomController = TextEditingController(text: p.groomName.isNotEmpty ? p.groomName : 'Sai Krishna');
    _brideController = TextEditingController(text: p.brideName.isNotEmpty ? p.brideName : 'Deepika');
    _ceremonyController = TextEditingController(text: p.ceremonyTitle.isNotEmpty ? p.ceremonyTitle : 'శుభ వివాహం / Subha Vivaham');
    _parentsController = TextEditingController(text: p.parentsNames.isNotEmpty ? p.parentsNames : 'Smt. Sarojini & Sri. Rama Rao');
    _dateController = TextEditingController(text: p.eventDate.isNotEmpty ? p.eventDate : 'Sunday, 15 December 2026');
    _timeController = TextEditingController(text: p.muhurthamTime.isNotEmpty ? p.muhurthamTime : 'Sumuhurtham: 10:24 AM');
    _venueController = TextEditingController(text: p.venue.isNotEmpty ? p.venue : 'Sri Venkateswara Kalyana Mandapam, Hyderabad');
    _rsvpController = TextEditingController(text: p.rsvp.isNotEmpty ? p.rsvp : 'With Best Compliments from Family & Friends');
  }

  @override
  void dispose() {
    _groomController.dispose();
    _brideController.dispose();
    _ceremonyController.dispose();
    _parentsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _rsvpController.dispose();
    super.dispose();
  }

  void _saveFormState() {
    context.read<PersonalizationProvider>().updateForm(
          groomName: _groomController.text.trim(),
          brideName: _brideController.text.trim(),
          ceremonyTitle: _ceremonyController.text.trim(),
          parentsNames: _parentsController.text.trim(),
          eventDate: _dateController.text.trim(),
          muhurthamTime: _timeController.text.trim(),
          venue: _venueController.text.trim(),
          rsvp: _rsvpController.text.trim(),
        );
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      _saveFormState();
      final tmpl = _getActiveTemplate();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewDetailsScreen(template: tmpl),
        ),
      );
    }
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

  Widget _buildPhotoSlot({
    required String label,
    required VoidCallback onTap,
    String? localPath,
    Uint8List? bytes,
    String? timeframe,
  }) {
    final hasCustom = bytes != null || (localPath != null && localPath.isNotEmpty && !kIsWeb);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF16161C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasCustom ? const Color(0xFFEAB308) : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasCustom
                ? (bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : Image.file(File(localPath!), fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (timeframe != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E26),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEAB308).withValues(alpha: 0.3), width: 0.8),
            ),
            child: Text(
              timeframe,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEAB308),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoGuideCard({
    required String title,
    required bool isGood,
    required IconData icon,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFF0F291E) : const Color(0xFF2B1115),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              Icon(
                isGood ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final tmpl = _getActiveTemplate();

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
          'Customize',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
              children: [
                // 1. Selected Template Header Card (tellow ai layout)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image(
                          image: _resolveImage(tmpl.thumbnailUrl),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFF262632),
                            child: const Icon(Icons.videocam, color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tmpl.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam_rounded, size: 10, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Video',
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.photo_outlined, size: 10, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${tmpl.photoSlotsCount}',
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code: VIV01   Processing time: ~30 seconds',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. User Profile Card (tellow ai layout)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Profile',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto-fill details from saved profiles. We select your most recently used profile by default.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'My profile (Sai Krishna)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'Switch',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. More Details - Photos Section (tellow ai layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.grid_view_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'More details',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Photos',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '2 photos required',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFE2E8F0),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await provider.pickManPhoto();
                            await provider.pickWomanPhoto();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262632),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Select Multiple',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
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
                const SizedBox(height: 14),

                // Dual Photo Slots: Man Photo & Woman Photo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoSlot(
                      label: 'Man photo',
                      timeframe: 'Scene 3: 00:41 - 00:51',
                      onTap: provider.pickManPhoto,
                      localPath: provider.data.manPhotoPath,
                      bytes: provider.data.manPhotoBytes,
                    ),
                    _buildPhotoSlot(
                      label: 'Woman photo',
                      timeframe: 'Scene 2: 00:28 - 00:38',
                      onTap: provider.pickWomanPhoto,
                      localPath: provider.data.womanPhotoPath,
                      bytes: provider.data.womanPhotoBytes,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Good vs Bad Photos Guide (Exact Match to Screenshot 4)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_size_select_actual_outlined, size: 18, color: Color(0xFFA78BFA)),
                          const SizedBox(width: 8),
                          Text(
                            'Good vs Bad Photos',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A few seconds here means a much better final video invitation.',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Horizontal Scrollable Cards Matching Screenshot 4
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPhotoGuideCard(
                              title: 'WHOLE FACE OPEN\nHANDS DOWN',
                              isGood: true,
                              icon: Icons.face_rounded,
                            ),
                            const SizedBox(width: 10),
                            _buildPhotoGuideCard(
                              title: 'FACE MASK\nHALF FACE HIDDEN',
                              isGood: false,
                              icon: Icons.masks_rounded,
                            ),
                            const SizedBox(width: 10),
                            _buildPhotoGuideCard(
                              title: 'STRAIGHT FACE\nEYES VISIBLE',
                              isGood: true,
                              icon: Icons.remove_red_eye_rounded,
                            ),
                            const SizedBox(width: 10),
                            _buildPhotoGuideCard(
                              title: 'SIDE OR BACK POSE\nDARK SUNGLASSES',
                              isGood: false,
                              icon: Icons.wb_sunny_rounded,
                            ),
                            const SizedBox(width: 10),
                            _buildPhotoGuideCard(
                              title: 'FACE FIRST\nPLAIN BACKGROUND',
                              isGood: true,
                              icon: Icons.portrait_rounded,
                            ),
                            const SizedBox(width: 10),
                            _buildPhotoGuideCard(
                              title: 'MIRROR SELFIE\nPHONE ON FACE',
                              isGood: false,
                              icon: Icons.smartphone_rounded,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Ceremony & Wedding Text Details
                Text(
                  'Wedding Invitation Details',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Groom Name (పెళ్లికొడుకు)',
                  controller: _groomController,
                  prefixIcon: Icons.man,
                  validator: (v) => v!.isEmpty ? 'Groom name is required' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Bride Name (పెళ్లికూతురు)',
                  controller: _brideController,
                  prefixIcon: Icons.woman,
                  validator: (v) => v!.isEmpty ? 'Bride name is required' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Ceremony Title (శుభకార్యం)',
                  controller: _ceremonyController,
                  prefixIcon: Icons.celebration,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Parents & Family Blessings',
                  controller: _parentsController,
                  prefixIcon: Icons.family_restroom,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Wedding Date (తేదీ)',
                  controller: _dateController,
                  prefixIcon: Icons.calendar_today,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Sumuhurtham Time (సుముహూర్తం)',
                  controller: _timeController,
                  prefixIcon: Icons.access_time,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'Kalyana Mandapam & Venue',
                  controller: _venueController,
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'RSVP / Greetings',
                  controller: _rsvpController,
                  prefixIcon: Icons.mail_outline,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 6. Sticky Bottom Action Bar (tellow ai layout)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E12),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _handleContinue,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Continue to create',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Next: preview & generate royal wedding video',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
