import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../rendering/video_processing_screen.dart';
import 'review_details_screen.dart';

class PersonalizationFormScreen extends StatefulWidget {
  final TemplateModel? template;

  const PersonalizationFormScreen({
    super.key,
    this.template,
  });

  @override
  State<PersonalizationFormScreen> createState() =>
      _PersonalizationFormScreenState();
}

class _PersonalizationFormScreenState extends State<PersonalizationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _groomController;
  late TextEditingController _brideController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _venueController;
  late TextEditingController _addressController;
  late TextEditingController _parentsController;
  late TextEditingController _ceremonyController;
  late TextEditingController _rsvpController;

  bool _isGenerating = false;

  TemplateModel _getActiveTemplate() {
    if (widget.template != null) return widget.template!;
    final selected = context.read<TemplateProvider>().selectedTemplate;
    if (selected != null) return selected;
    final templates = context.read<TemplateProvider>().templates;
    if (templates.isNotEmpty) return templates.first;
    return TemplateModel(
      id: 'tmpl_telugu_chroma_01',
      title: 'Telugu Vivaham Mandapam',
      category: 'Wedding',
      religion: 'Hindu',
      orientation: '16:9',
      hasPhoto: true,
      photoSlotsCount: 5,
      durationSeconds: 102,
      badgeText: 'CHROMA PRO',
      description: 'Traditional Telugu Vivaham',
      masterVideoPath: 'assets/templates/template_01_green_screen.mp4',
      thumbnailUrl: 'assets/templates/thumb_01_green.jpg',
    );
  }

  @override
  void initState() {
    super.initState();
    final p = context.read<PersonalizationProvider>().data;

    _groomController = TextEditingController(
        text: p.groomName.isNotEmpty ? p.groomName : 'Sai Krishna');
    _brideController = TextEditingController(
        text: p.brideName.isNotEmpty ? p.brideName : 'Deepika');
    _dateController = TextEditingController(
        text: p.eventDate.isNotEmpty ? p.eventDate : 'Sunday, 15 December 2026');
    _timeController = TextEditingController(
        text: p.muhurthamTime.isNotEmpty
            ? p.muhurthamTime
            : 'Sumuhurtham: 10:24 AM');
    _venueController = TextEditingController(
        text: p.venue.isNotEmpty
            ? p.venue
            : 'Sri Venkateswara Kalyana Mandapam');
    _addressController = TextEditingController(
        text: 'Banjara Hills, Road No. 12, Hyderabad');
    _parentsController = TextEditingController(
        text: p.parentsNames.isNotEmpty
            ? p.parentsNames
            : 'Smt. Sarojini & Sri. Rama Rao');
    _ceremonyController = TextEditingController(
        text: p.ceremonyTitle.isNotEmpty
            ? p.ceremonyTitle
            : 'శుభ వివాహం / Subha Vivaham');
    _rsvpController = TextEditingController(
        text: p.rsvp.isNotEmpty
            ? p.rsvp
            : 'With Best Compliments from Family & Friends');
  }

  @override
  void dispose() {
    _groomController.dispose();
    _brideController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _parentsController.dispose();
    _ceremonyController.dispose();
    _rsvpController.dispose();
    super.dispose();
  }

  void _saveFormState() {
    final fullVenue = _addressController.text.trim().isNotEmpty
        ? '${_venueController.text.trim()}, ${_addressController.text.trim()}'
        : _venueController.text.trim();

    context.read<PersonalizationProvider>().updateForm(
          groomName: _groomController.text.trim(),
          brideName: _brideController.text.trim(),
          ceremonyTitle: _ceremonyController.text.trim(),
          parentsNames: _parentsController.text.trim(),
          eventDate: _dateController.text.trim(),
          muhurthamTime: _timeController.text.trim(),
          venue: fullVenue,
          rsvp: _rsvpController.text.trim(),
        );
  }

  void _handleGenerateVideo() {
    if (_isGenerating) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.royalCrimson,
          content: Text('Please complete all mandatory wedding fields.'),
        ),
      );
      return;
    }

    final tmpl = _getActiveTemplate();
    final p = context.read<PersonalizationProvider>();

    // Validate photos if required by template
    if (tmpl.hasPhoto) {
      final hasWoman = p.data.womanPhotoBytes != null ||
          (p.data.womanPhotoPath != null && p.data.womanPhotoPath!.isNotEmpty);
      final hasMan = p.data.manPhotoBytes != null ||
          (p.data.manPhotoPath != null && p.data.manPhotoPath!.isNotEmpty);
      final hasSlotPhoto = p.data.slotPhotoPaths.isNotEmpty ||
          p.data.slotPhotoBytes.isNotEmpty;

      if (!hasWoman && !hasMan && !hasSlotPhoto) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFC2410C),
            content: Text(
              'Please upload at least one photo for this template, or continue with default placeholders.',
            ),
          ),
        );
      }
    }

    setState(() => _isGenerating = true);
    _saveFormState();

    // Navigate to VideoProcessingScreen with active template
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoProcessingScreen(template: tmpl),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    });
  }

  void _handleReviewDetails() {
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

  Widget _buildTemplatePreviewHeader(TemplateModel tmpl) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image(
                  image: _resolveImage(tmpl.thumbnailUrl),
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFF22222E),
                    child: const Icon(Icons.videocam, color: Colors.white38),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tmpl.orientation == '16:9'
                            ? '16:9 Horizontal'
                            : '9:16 Vertical',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.champagne,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: tmpl.hasPhoto
                            ? AppColors.brandPink.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tmpl.hasPhoto
                            ? '${tmpl.photoSlotsCount} Photos'
                            : 'Without Photo',
                        style: GoogleFonts.plusJakartaSans(
                          color: tmpl.hasPhoto
                              ? const Color(0xFFFF7597)
                              : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${tmpl.durationSeconds}s • Full HD Video Generation',
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
    );
  }

  Widget _buildPhotoSlotCard({
    required String label,
    required String slotRole,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    String? localPath,
    Uint8List? bytes,
  }) {
    return Expanded(
      child: _buildPhotoSlotCardItem(
        label: label,
        slotRole: slotRole,
        onPick: onPick,
        onRemove: onRemove,
        localPath: localPath,
        bytes: bytes,
      ),
    );
  }

  Widget _buildPhotoSlotCardItem({
    required String label,
    required String slotRole,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    String? localPath,
    Uint8List? bytes,
  }) {
    final hasPhoto = bytes != null || (localPath != null && localPath.isNotEmpty);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF14141B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasPhoto
                    ? AppColors.brandPink
                    : Colors.white.withValues(alpha: 0.15),
                width: hasPhoto ? 2 : 1,
              ),
              boxShadow: hasPhoto
                  ? [
                      BoxShadow(
                        color: AppColors.brandPink.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (hasPhoto) ...[
                  Positioned.fill(
                    child: bytes != null
                        ? Image.memory(bytes, fit: BoxFit.cover)
                        : (!kIsWeb && localPath != null
                            ? Image.file(File(localPath), fit: BoxFit.cover)
                            : Container(
                                color: const Color(0xFF22222E),
                                child: const Icon(Icons.check,
                                    color: AppColors.primaryGold, size: 36),
                              )),
                  ),
                  // Remove button top right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Replace banner at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: onPick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Center(
                          child: Text(
                            'Replace',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Empty slot upload trigger
                  GestureDetector(
                    onTap: onPick,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.brandPink.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.brandPink,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Photo',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PNG / JPG',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            slotRole,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
            ),
          ),
        ],
      );
  }

  Widget _buildPhotoUploadSection(
      PersonalizationProvider provider, TemplateModel tmpl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: AppColors.brandPink,
                ),
                const SizedBox(width: 8),
                Text(
                  'Upload Photos',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tmpl.photoSlotsCount} ${tmpl.photoSlotsCount == 1 ? "photo" : "photos"} required',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.champagne,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Dynamic Multi-Photo Upload Slots from published Template Configuration
        if (tmpl.imageElements.isNotEmpty) ...[
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: tmpl.imageElements.map((imgEl) {
              final slotKey = imgEl.field;
              final slotBytes = provider.data.getSlotPhotoBytes(slotKey);
              final slotPath = provider.data.getSlotPhotoPath(slotKey);
              final animName = imgEl.animationType == 'ink_reveal'
                  ? 'Ink Reveal'
                  : imgEl.animationType == 'brush_stroke'
                      ? 'Brush Stroke'
                      : 'Fade';

              return SizedBox(
                width: 155,
                child: _buildPhotoSlotCardItem(
                  label: imgEl.label.isNotEmpty ? imgEl.label : slotKey,
                  slotRole: '$animName (${imgEl.startTime.toInt()}s-${imgEl.endTime.toInt()}s)',
                  onPick: () => provider.pickSlotPhoto(slotKey),
                  onRemove: () => provider.removeSlotPhoto(slotKey),
                  localPath: slotPath,
                  bytes: slotBytes,
                ),
              );
            }).toList(),
          ),
        ] else if (tmpl.photoSlotsCount >= 2) ...[
          Row(
            children: [
              _buildPhotoSlotCard(
                label: "Groom's Photo",
                slotRole: 'పెళ్లికొడుకు ఫోటో',
                onPick: provider.pickManPhoto,
                onRemove: provider.removeManPhoto,
                localPath: provider.data.manPhotoPath,
                bytes: provider.data.manPhotoBytes,
              ),
              const SizedBox(width: 14),
              _buildPhotoSlotCard(
                label: "Bride's Photo",
                slotRole: 'పెళ్లికూతురు ఫోటో',
                onPick: provider.pickWomanPhoto,
                onRemove: provider.removeWomanPhoto,
                localPath: provider.data.womanPhotoPath,
                bytes: provider.data.womanPhotoBytes,
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              _buildPhotoSlotCard(
                label: 'Couple Photo',
                slotRole: 'జంట ఫోటో',
                onPick: provider.pickWomanPhoto,
                onRemove: provider.removeWomanPhoto,
                localPath: provider.data.womanPhotoPath,
                bytes: provider.data.womanPhotoBytes,
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),

        // Photo Placement & Framing Action Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.crop_rotate_rounded, color: AppColors.primaryGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Photo Placement & Framing',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _openPhotoPlacementSheet(provider),
                    icon: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryGold),
                    label: Text(
                      'Adjust',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: AppColors.primaryGold.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Selected: ${provider.data.photoPlacement.toUpperCase()} • Scale ${(provider.data.photoScale * 100).toInt()}% • Offset (${provider.data.photoOffsetX.toInt()}px, ${provider.data.photoOffsetY.toInt()}px)',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.champagne,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Photo Tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF14141B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryGold,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Use clear, well-lit portraits looking directly at camera for best AI chroma & framing quality.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPresetChip(
    String value,
    String label,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : Colors.white12,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPhotoPlacementSheet(PersonalizationProvider provider) {
    double tempScale = provider.data.photoScale;
    double tempOffsetX = provider.data.photoOffsetX;
    double tempOffsetY = provider.data.photoOffsetY;
    String tempPlacement = provider.data.photoPlacement;

    final hasPhoto = provider.data.womanPhotoBytes != null ||
        provider.data.manPhotoBytes != null ||
        (provider.data.womanPhotoPath != null && provider.data.womanPhotoPath!.isNotEmpty) ||
        (provider.data.manPhotoPath != null && provider.data.manPhotoPath!.isNotEmpty);
    final photoBytes = provider.data.womanPhotoBytes ?? provider.data.manPhotoBytes;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.crop_rotate_rounded, color: AppColors.primaryGold, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Photo Placement & Framing',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Position where your photo appears within the video invitation frame.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Framing Preview Box
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.goldBorder, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Color(0xFF1F1D2B),
                                Color(0xFF0F0E17),
                              ],
                            ),
                          ),
                        ),
                        // Photo with applied offset & scale
                        Transform.translate(
                          offset: Offset(tempOffsetX, tempOffsetY),
                          child: Transform.scale(
                            scale: tempScale,
                            child: hasPhoto && photoBytes != null
                                ? Image.memory(
                                    photoBytes,
                                    height: 140,
                                    width: 140,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 140,
                                    width: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.surfaceHigh,
                                      border: Border.all(color: AppColors.brandPink, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 64,
                                      color: AppColors.primaryGold,
                                    ),
                                  ),
                          ),
                        ),
                        // Golden Arch / Oval Frame Overlay
                        IgnorePointer(
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                tempPlacement == 'full' ? 16 : 100,
                              ),
                              border: Border.all(
                                color: AppColors.primaryGold.withValues(alpha: 0.6),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Helper pill
                        Positioned(
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Placement: ${tempPlacement.toUpperCase()} • Scale: ${(tempScale * 100).toInt()}%',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.champagne,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Placement presets
                  Text(
                    'Frame Position Preset',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPresetChip('center', 'Arch Center', tempPlacement, (p) {
                        setModalState(() {
                          tempPlacement = p;
                          tempOffsetX = 0.0;
                          tempOffsetY = 0.0;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildPresetChip('left', 'Left Frame', tempPlacement, (p) {
                        setModalState(() {
                          tempPlacement = p;
                          tempOffsetX = -25.0;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildPresetChip('right', 'Right Frame', tempPlacement, (p) {
                        setModalState(() {
                          tempPlacement = p;
                          tempOffsetX = 25.0;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildPresetChip('full', 'Full View', tempPlacement, (p) {
                        setModalState(() {
                          tempPlacement = p;
                          tempScale = 1.15;
                          tempOffsetX = 0.0;
                          tempOffsetY = 0.0;
                        });
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sliders: Scale / Zoom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photo Scale / Zoom: ${(tempScale * 100).toInt()}%',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          tempScale = 1.0;
                          tempOffsetX = 0.0;
                          tempOffsetY = 0.0;
                        }),
                        child: Text('Reset', style: GoogleFonts.plusJakartaSans(color: AppColors.primaryGold, fontSize: 11)),
                      ),
                    ],
                  ),
                  Slider(
                    value: tempScale.clamp(0.8, 1.6),
                    min: 0.8,
                    max: 1.6,
                    divisions: 16,
                    activeColor: AppColors.primaryGold,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setModalState(() => tempScale = v),
                  ),

                  // Sliders: Horizontal Offset
                  Text(
                    'Horizontal Position (X): ${tempOffsetX.toInt()}px',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                  ),
                  Slider(
                    value: tempOffsetX.clamp(-60.0, 60.0),
                    min: -60.0,
                    max: 60.0,
                    divisions: 24,
                    activeColor: AppColors.brandPink,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setModalState(() => tempOffsetX = v),
                  ),

                  // Sliders: Vertical Offset
                  Text(
                    'Vertical Position (Y): ${tempOffsetY.toInt()}px',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12),
                  ),
                  Slider(
                    value: tempOffsetY.clamp(-60.0, 60.0),
                    min: -60.0,
                    max: 60.0,
                    divisions: 24,
                    activeColor: AppColors.champagne,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setModalState(() => tempOffsetY = v),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      provider.updatePhotoPlacement(
                        placement: tempPlacement,
                        scale: tempScale,
                        offsetX: tempOffsetX,
                        offsetY: tempOffsetY,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF166534),
                          content: Text('Photo placement & framing saved!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Apply Photo Placement',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
          'Customize Invitation',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _handleReviewDetails,
            child: Text(
              'Review',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.primaryGold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
              children: [
                // 1. Template Preview Banner
                _buildTemplatePreviewHeader(tmpl),
                const SizedBox(height: 20),

                // 2. Photo Upload Section (Rendered ONLY if template.hasPhoto == true)
                if (tmpl.hasPhoto)
                  _buildPhotoUploadSection(provider, tmpl),

                // 3. Wedding Information Fields
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: AppColors.primaryGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wedding Information',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'These details will be rendered on the invitation video',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Bride Name (Required)
                CustomTextField(
                  label: "Bride's Name (పెళ్లికూతురు)",
                  controller: _brideController,
                  prefixIcon: Icons.woman_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Bride's name is required" : null,
                ),
                const SizedBox(height: 14),

                // Groom Name (Required)
                CustomTextField(
                  label: "Groom's Name (పెళ్లికొడుకు)",
                  controller: _groomController,
                  prefixIcon: Icons.man_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Groom's name is required" : null,
                ),
                const SizedBox(height: 14),

                // Wedding Date (Required)
                CustomTextField(
                  label: 'Wedding Date (తేదీ)',
                  controller: _dateController,
                  prefixIcon: Icons.calendar_month_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wedding date is required' : null,
                ),
                const SizedBox(height: 14),

                // Wedding Time / Muhurtham (Required)
                CustomTextField(
                  label: 'Wedding Time / Sumuhurtham (సుముహూర్తం)',
                  controller: _timeController,
                  prefixIcon: Icons.access_time_filled_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wedding time is required' : null,
                ),
                const SizedBox(height: 14),

                // Wedding Venue (Required)
                CustomTextField(
                  label: 'Wedding Venue / Kalyana Mandapam (కల్యాణ మండపం)',
                  controller: _venueController,
                  prefixIcon: Icons.temple_hindu_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wedding venue is required' : null,
                ),
                const SizedBox(height: 14),

                // Wedding Location / Address
                CustomTextField(
                  label: 'Wedding Location / Address (చిరునామా)',
                  controller: _addressController,
                  prefixIcon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 14),

                // Parents' / Family names
                CustomTextField(
                  label: "Parents' or Family Names (తల్లిదండ్రుల ఆశీస్సులు)",
                  controller: _parentsController,
                  prefixIcon: Icons.family_restroom_rounded,
                ),
                const SizedBox(height: 14),

                // Additional Ceremony Details / RSVP
                CustomTextField(
                  label: 'Ceremony Title / Greetings (శుభకార్యం)',
                  controller: _ceremonyController,
                  prefixIcon: Icons.celebration_rounded,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'RSVP / Cordial Welcome',
                  controller: _rsvpController,
                  prefixIcon: Icons.mark_email_read_rounded,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // 4. Sticky Bottom Action Bar with "Generate Video"
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E12),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _handleGenerateVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        disabledBackgroundColor: const Color(0xFF1E1E26),
                        foregroundColor: Colors.black,
                        disabledForegroundColor: const Color(0xFF64748B),
                        elevation: _isGenerating ? 0 : 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _isGenerating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Preparing Video Engine...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.movie_creation_rounded,
                                  size: 19,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Generate Video',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Instant rendering with authentic Telugu wedding music & sacred shlokas',
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
