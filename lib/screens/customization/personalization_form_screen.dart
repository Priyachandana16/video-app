import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../services/api_service.dart';
import '../../providers/personalization_provider.dart';
import '../../providers/template_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../rendering/video_processing_screen.dart';
import 'review_details_screen.dart';

class PersonalizationFormScreen extends StatefulWidget {
  final TemplateModel? template;
  final bool? hasPhotoPreference;

  const PersonalizationFormScreen({
    super.key,
    this.template,
    this.hasPhotoPreference,
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

  // Dynamic text element controllers mapped from Admin Panel text layers
  final Map<String, TextEditingController> _dynamicControllers = {};

  bool _isGenerating = false;
  TemplateModel? _fullTemplate;

  bool get _isWithPhotos {
    if (widget.hasPhotoPreference != null) {
      return widget.hasPhotoPreference! && _getActiveTemplate().hasPhoto;
    }
    final userPref = context.read<PersonalizationProvider>().userPhotoPreference;
    if (userPref != null) {
      return userPref && _getActiveTemplate().hasPhoto;
    }
    final providerHasPhoto = context.read<PersonalizationProvider>().data.hasPhoto;
    return providerHasPhoto && _getActiveTemplate().hasPhoto;
  }

  TemplateModel _getActiveTemplate() {
    if (_fullTemplate != null) return _fullTemplate!;
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

  void _initDynamicControllers(TemplateModel tmpl) {
    final p = context.read<PersonalizationProvider>().data;
    for (final txtEl in tmpl.textElements) {
      if (!_dynamicControllers.containsKey(txtEl.field)) {
        final existingVal = p.getCustomText(txtEl.field);
        // Start empty so the template default text shows as low-opacity placeholder hint
        final initialVal = existingVal.isNotEmpty ? existingVal : '';
        _dynamicControllers[txtEl.field] = TextEditingController(text: initialVal);
      }
    }
  }

  TextEditingController _getControllerForElement(TemplateTextElement txtEl) {
    if (!_dynamicControllers.containsKey(txtEl.field)) {
      final p = context.read<PersonalizationProvider>().data;
      final existingVal = p.getCustomText(txtEl.field);
      // Start empty so the template default text shows as low-opacity placeholder hint
      final initialVal = existingVal.isNotEmpty ? existingVal : '';
      _dynamicControllers[txtEl.field] = TextEditingController(text: initialVal);
    }
    return _dynamicControllers[txtEl.field]!;
  }

  IconData _getIconForField(String field) {
    final f = field.toLowerCase();
    if (f.contains('bride') || f.contains('woman')) return Icons.woman_rounded;
    if (f.contains('groom') || f.contains('man')) return Icons.man_rounded;
    if (f.contains('ceremony') || f.contains('title') || f.contains('header')) return Icons.celebration_rounded;
    if (f.contains('date')) return Icons.calendar_month_rounded;
    if (f.contains('time') || f.contains('muhurtham')) return Icons.access_time_filled_rounded;
    if (f.contains('venue') || f.contains('mandapam') || f.contains('hall') || f.contains('location') || f.contains('address')) return Icons.temple_hindu_rounded;
    if (f.contains('rsvp') || f.contains('regards') || f.contains('welcome')) return Icons.mark_email_read_rounded;
    if (f.contains('parent') || f.contains('family')) return Icons.family_restroom_rounded;
    return Icons.edit_note_rounded;
  }

  Future<void> _fetchFullTemplateConfig() async {
    final active = _getActiveTemplate();
    if (active.imageElements.isEmpty || active.textElements.isEmpty) {
      final full = await ApiService.instance.getTemplateById(active.id);
      if (full != null && mounted) {
        setState(() {
          _fullTemplate = full;
          _initDynamicControllers(full);
        });
      }
    } else {
      _initDynamicControllers(active);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchFullTemplateConfig();
    final provider = context.read<PersonalizationProvider>();
    if (widget.hasPhotoPreference != null) {
      provider.setPhotoPreference(widget.hasPhotoPreference!);
    }
    final p = provider.data;

    _groomController = TextEditingController(text: p.groomName);
    _brideController = TextEditingController(text: p.brideName);
    _dateController = TextEditingController(text: p.eventDate);
    _timeController = TextEditingController(text: p.muhurthamTime);
    _venueController = TextEditingController(text: p.venue);
    _addressController = TextEditingController(text: '');
    _parentsController = TextEditingController(text: p.parentsNames);
    _ceremonyController = TextEditingController(text: p.ceremonyTitle);
    _rsvpController = TextEditingController(text: p.rsvp);

    _initDynamicControllers(_getActiveTemplate());
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

    for (final ctrl in _dynamicControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _saveFormState() {
    final tmpl = _getActiveTemplate();
    final provider = context.read<PersonalizationProvider>();

    if (tmpl.textElements.isNotEmpty) {
      final Map<String, String> values = {};
      for (final txtEl in tmpl.textElements) {
        final ctrl = _getControllerForElement(txtEl);
        final entered = ctrl.text.trim();
        // If left empty, smoothly use the template default text from admin
        values[txtEl.field] = entered.isNotEmpty ? entered : txtEl.defaultText;
      }
      provider.updateCustomTexts(values);

      // Keep legacy fields in sync for backward compatibility
      if (values.containsKey('brideName')) provider.data.brideName = values['brideName']!;
      if (values.containsKey('groomName')) provider.data.groomName = values['groomName']!;
      if (values.containsKey('ceremonyTitle')) provider.data.ceremonyTitle = values['ceremonyTitle']!;
      if (values.containsKey('eventDate')) provider.data.eventDate = values['eventDate']!;
      if (values.containsKey('muhurthamTime')) provider.data.muhurthamTime = values['muhurthamTime']!;
      if (values.containsKey('venue')) provider.data.venue = values['venue']!;
      if (values.containsKey('rsvp')) provider.data.rsvp = values['rsvp']!;
    } else {
      final fullVenue = _addressController.text.trim().isNotEmpty
          ? '${_venueController.text.trim()}, ${_addressController.text.trim()}'
          : _venueController.text.trim();

      provider.updateForm(
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
  }

  Future<void> _pickDateForController(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGold,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E28),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final formatted = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Future<void> _pickTimeForController(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGold,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E28),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final formatted = '$hour:$minute $period';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGold,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E28),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final formatted = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        _dateController.text = formatted;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGold,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E28),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final formatted = '$hour:$minute $period';
      setState(() {
        _timeController.text = formatted;
      });
    }
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

    // Validate photos ONLY if user selected With Photos AND template requires them
    if (_isWithPhotos && tmpl.hasPhoto) {
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
          builder: (_) => ReviewDetailsScreen(
            template: tmpl,
            hasPhoto: _isWithPhotos,
          ),
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
                        color: (_isWithPhotos && tmpl.hasPhoto)
                            ? AppColors.brandPink.withValues(alpha: 0.15)
                            : const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (_isWithPhotos && tmpl.hasPhoto)
                            ? '${tmpl.photoSlotsCount} Photos'
                            : 'Without Photos',
                        style: GoogleFonts.plusJakartaSans(
                          color: (_isWithPhotos && tmpl.hasPhoto)
                              ? const Color(0xFFFF7597)
                              : const Color(0xFF6EE7B7),
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
    VoidCallback? onAdjust,
    String? localPath,
    Uint8List? bytes,
  }) {
    return Expanded(
      child: _buildPhotoSlotCardItem(
        label: label,
        slotRole: slotRole,
        onPick: onPick,
        onRemove: onRemove,
        onAdjust: onAdjust,
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
    VoidCallback? onAdjust,
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
                    child: GestureDetector(
                      onTap: onPick,
                      behavior: HitTestBehavior.opaque,
                      child: bytes != null
                          ? Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: const Color(0xFF22222E),
                                child: const Center(
                                  child: Icon(Icons.check, color: AppColors.primaryGold, size: 36),
                                ),
                              ),
                            )
                          : (kIsWeb && localPath != null
                              ? Image.network(
                                  localPath,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    color: const Color(0xFF22222E),
                                    child: const Center(
                                      child: Icon(Icons.check, color: AppColors.primaryGold, size: 36),
                                    ),
                                  ),
                                )
                              : (!kIsWeb && localPath != null
                                  ? Image.file(File(localPath), fit: BoxFit.cover)
                                  : Container(
                                      color: const Color(0xFF22222E),
                                      child: const Center(
                                        child: Icon(Icons.check, color: AppColors.primaryGold, size: 36),
                                      ),
                                    ))),
                    ),
                  ),
                  // Adjust button top left
                  if (onAdjust != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        onTap: onAdjust,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.85), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tune_rounded, color: AppColors.primaryGold, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Adjust',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Remove button top right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 15),
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
                        color: Colors.black.withValues(alpha: 0.75),
                        child: Center(
                          child: Text(
                            'Tap to Replace',
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
                  // Empty slot upload trigger - Positioned.fill ensures entire box is clickable
                  Positioned.fill(
                    child: GestureDetector(
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
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
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
            slotRole,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                  onPick: () async {
                    await provider.pickSlotPhoto(slotKey);
                    if (mounted) setState(() {});
                  },
                  onRemove: () {
                    provider.removeSlotPhoto(slotKey);
                    if (mounted) setState(() {});
                  },
                  onAdjust: () => _openPhotoPlacementSheet(provider, targetSlotKey: slotKey),
                  localPath: slotPath,
                  bytes: slotBytes,
                ),
              );
            }).toList(),
          ),
        ] else if (tmpl.photoSlotsCount > 2) ...[
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: List.generate(tmpl.photoSlotsCount, (index) {
              final slotKey = 'photo_${index + 1}';
              final slotBytes = provider.data.getSlotPhotoBytes(slotKey);
              final slotPath = provider.data.getSlotPhotoPath(slotKey);
              final defaultLabel = index == 0
                  ? "Groom's Photo"
                  : index == 1
                      ? "Bride's Photo"
                      : "Photo ${index + 1}";
              final defaultRole = index == 0
                  ? "పెళ్లికొడుకు ఫోటో"
                  : index == 1
                      ? "పెళ్లికూతురు ఫోటో"
                      : "ఫోటో ${index + 1}";

              return SizedBox(
                width: 155,
                child: _buildPhotoSlotCardItem(
                  label: defaultLabel,
                  slotRole: defaultRole,
                  onPick: () async {
                    await provider.pickSlotPhoto(slotKey);
                    if (mounted) setState(() {});
                  },
                  onRemove: () {
                    provider.removeSlotPhoto(slotKey);
                    if (mounted) setState(() {});
                  },
                  onAdjust: () => _openPhotoPlacementSheet(provider, targetSlotKey: slotKey),
                  localPath: slotPath,
                  bytes: slotBytes,
                ),
              );
            }),
          ),
        ] else if (tmpl.photoSlotsCount == 2) ...[
          Row(
            children: [
              _buildPhotoSlotCard(
                label: "Groom's Photo",
                slotRole: 'పెళ్లికొడుకు ఫోటో',
                onPick: () async {
                  await provider.pickManPhoto();
                  if (mounted) setState(() {});
                },
                onRemove: () {
                  provider.removeManPhoto();
                  if (mounted) setState(() {});
                },
                onAdjust: () => _openPhotoPlacementSheet(provider, targetSlotKey: 'photo_2'),
                localPath: provider.data.manPhotoPath,
                bytes: provider.data.manPhotoBytes,
              ),
              const SizedBox(width: 14),
              _buildPhotoSlotCard(
                label: "Bride's Photo",
                slotRole: 'పెళ్లికూతురు ఫోటో',
                onPick: () async {
                  await provider.pickWomanPhoto();
                  if (mounted) setState(() {});
                },
                onRemove: () {
                  provider.removeWomanPhoto();
                  if (mounted) setState(() {});
                },
                onAdjust: () => _openPhotoPlacementSheet(provider, targetSlotKey: 'photo_1'),
                localPath: provider.data.womanPhotoPath,
                bytes: provider.data.womanPhotoBytes,
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              _buildPhotoSlotCard(
                label: tmpl.category == 'Half Saree Ceremony'
                    ? "Girl's Photo (చిరంజీవి ఫోటో)"
                    : (tmpl.category == 'Birthday'
                        ? "Birthday Star's Photo"
                        : (tmpl.category == 'Housewarming'
                            ? "Family Home Photo"
                            : "Couple Photo")),
                slotRole: tmpl.category == 'Half Saree Ceremony'
                    ? 'లంగా వోణి ఫోటో'
                    : (tmpl.category == 'Birthday'
                        ? 'బర్త్‌డే ఫోటో'
                        : 'జంట ఫోటో'),
                onPick: provider.pickWomanPhoto,
                onRemove: provider.removeWomanPhoto,
                onAdjust: () => _openPhotoPlacementSheet(provider, targetSlotKey: 'photo_1'),
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
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.crop_rotate_rounded, color: AppColors.primaryGold, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photo Framing & Shapes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _openPhotoPlacementSheet(provider),
                    icon: const Icon(Icons.tune_rounded, size: 15, color: AppColors.primaryGold),
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
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust framing, zoom & shapes (Rectangle, Circle/Round, Oval) for all uploaded photos.',
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
              textAlign: TextAlign.center,
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

  Widget _buildClippedPhotoPreview({
    Uint8List? bytes,
    String? localPath,
    required bool hasPhoto,
    required String shape,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) {
    Widget imageContent;
    if (hasPhoto && bytes != null) {
      imageContent = Image.memory(bytes, fit: BoxFit.cover, width: 130, height: 130);
    } else if (hasPhoto && localPath != null && localPath.isNotEmpty) {
      imageContent = kIsWeb
          ? Image.network(localPath, fit: BoxFit.cover, width: 130, height: 130)
          : Image.file(File(localPath), fit: BoxFit.cover, width: 130, height: 130);
    } else {
      imageContent = Container(
        width: 130,
        height: 130,
        color: AppColors.surfaceHigh,
        child: const Icon(Icons.person_rounded, size: 54, color: AppColors.primaryGold),
      );
    }

    final transformed = Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.scale(
        scale: scale,
        child: imageContent,
      ),
    );

    if (shape == 'circle') {
      return ClipOval(
        child: SizedBox(width: 130, height: 130, child: transformed),
      );
    } else if (shape == 'oval') {
      return ClipOval(
        child: SizedBox(width: 110, height: 145, child: transformed),
      );
    } else if (shape == 'rounded') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(width: 125, height: 135, child: transformed),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: 125, height: 135, child: transformed),
    );
  }

  Widget _buildShapeBorderOverlay(String shape) {
    if (shape == 'circle') {
      return Container(
        width: 134,
        height: 134,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryGold, width: 2.2),
        ),
      );
    } else if (shape == 'oval') {
      return Container(
        width: 114,
        height: 149,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.elliptical(57, 74)),
          border: Border.all(color: AppColors.primaryGold, width: 2.2),
        ),
      );
    } else if (shape == 'rounded') {
      return Container(
        width: 129,
        height: 139,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primaryGold, width: 2),
        ),
      );
    }
    return Container(
      width: 129,
      height: 139,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryGold, width: 2),
      ),
    );
  }

  void _openPhotoPlacementSheet(PersonalizationProvider provider, {String? targetSlotKey}) {
    final tmpl = _getActiveTemplate();

    // 1. Gather all slot definitions available for this template
    final List<Map<String, String>> availableSlots = [];
    if (tmpl.imageElements.isNotEmpty) {
      for (int i = 0; i < tmpl.imageElements.length; i++) {
        final imgEl = tmpl.imageElements[i];
        final key = imgEl.field.isNotEmpty ? imgEl.field : 'photo_${i + 1}';
        final label = imgEl.label.isNotEmpty ? imgEl.label : 'Photo ${i + 1}';
        availableSlots.add({'key': key, 'label': label});
      }
    } else if (tmpl.photoSlotsCount > 2) {
      for (int i = 0; i < tmpl.photoSlotsCount; i++) {
        final key = 'photo_${i + 1}';
        final label = i == 0 ? "Groom" : i == 1 ? "Bride" : "Photo ${i + 1}";
        availableSlots.add({'key': key, 'label': label});
      }
    } else if (tmpl.photoSlotsCount == 2) {
      availableSlots.add({'key': 'photo_2', 'label': "Groom (పెళ్లికొడుకు)"});
      availableSlots.add({'key': 'photo_1', 'label': "Bride (పెళ్లికూతురు)"});
    } else {
      availableSlots.add({'key': 'photo_1', 'label': "Photo 1"});
    }

    // Default current slot
    String currentSlot = targetSlotKey ?? (availableSlots.isNotEmpty ? availableSlots.first['key']! : 'photo_1');
    if (!availableSlots.any((s) => s['key'] == currentSlot) && availableSlots.isNotEmpty) {
      currentSlot = availableSlots.first['key']!;
    }

    double tempScale = provider.data.getSlotScale(currentSlot);
    double tempOffsetX = provider.data.getSlotOffsetX(currentSlot);
    double tempOffsetY = provider.data.getSlotOffsetY(currentSlot);
    String tempShape = provider.data.getSlotShape(currentSlot);
    String tempPlacement = provider.data.photoPlacement;

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
            // Get photo bytes & path for the currently selected slot
            final currentBytes = provider.data.getSlotPhotoBytes(currentSlot);
            final currentPath = provider.data.getSlotPhotoPath(currentSlot);
            final hasPhoto = currentBytes != null || (currentPath != null && currentPath.isNotEmpty);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                              'Photo Framing & Shape Adjustment',
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
                      'Select a photo slot, customize framing shape (Round/Rectangle), zoom, and positioning.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Slot Switcher Chips (when multiple slots exist)
                    if (availableSlots.length > 1) ...[
                      Text(
                        'Select Photo Slot to Adjust:',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.champagne,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableSlots.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (_, idx) {
                            final slot = availableSlots[idx];
                            final isSel = slot['key'] == currentSlot;
                            final sBytes = provider.data.getSlotPhotoBytes(slot['key']!);
                            final hasSlotPic = sBytes != null || (provider.data.getSlotPhotoPath(slot['key']!)?.isNotEmpty ?? false);

                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasSlotPic ? Icons.check_circle_rounded : Icons.photo_outlined,
                                    size: 14,
                                    color: isSel ? Colors.black : (hasSlotPic ? AppColors.primaryGold : Colors.white60),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(slot['label']!),
                                ],
                              ),
                              selected: isSel,
                              selectedColor: AppColors.primaryGold,
                              backgroundColor: const Color(0xFF1E1E2A),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                color: isSel ? Colors.black : Colors.white70,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 11,
                              ),
                              onSelected: (_) {
                                setModalState(() {
                                  currentSlot = slot['key']!;
                                  tempScale = provider.data.getSlotScale(currentSlot);
                                  tempOffsetX = provider.data.getSlotOffsetX(currentSlot);
                                  tempOffsetY = provider.data.getSlotOffsetY(currentSlot);
                                  tempShape = provider.data.getSlotShape(currentSlot);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Frame Shape Selection: Rectangle, Circle / Round, Oval, Rounded
                    Text(
                      'Photo Frame Shape (క్రాపింగ్ ఆకారం)',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPresetChip('rectangle', 'Rectangle / చతురస్రం', tempShape, (s) {
                          setModalState(() => tempShape = s);
                        }),
                        const SizedBox(width: 6),
                        _buildPresetChip('circle', 'Circle / గుండ్రంగా', tempShape, (s) {
                          setModalState(() => tempShape = s);
                        }),
                        const SizedBox(width: 6),
                        _buildPresetChip('oval', 'Oval / అండాకారం', tempShape, (s) {
                          setModalState(() => tempShape = s);
                        }),
                        const SizedBox(width: 6),
                        _buildPresetChip('rounded', 'Rounded / వంపు', tempShape, (s) {
                          setModalState(() => tempShape = s);
                        }),
                      ],
                    ),
                    const SizedBox(height: 14),

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
                          // Masked photo preview based on selected shape
                          Center(
                            child: _buildClippedPhotoPreview(
                              bytes: currentBytes,
                              localPath: currentPath,
                              hasPhoto: hasPhoto,
                              shape: tempShape,
                              scale: tempScale,
                              offsetX: tempOffsetX,
                              offsetY: tempOffsetY,
                            ),
                          ),
                          // Shape Overlay outline border
                          IgnorePointer(
                            child: _buildShapeBorderOverlay(tempShape),
                          ),
                          // Helper pill at bottom
                          Positioned(
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Slot: ${currentSlot.toUpperCase()} • Shape: ${tempShape.toUpperCase()} • Zoom: ${(tempScale * 100).toInt()}%',
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
                      value: tempScale.clamp(0.7, 2.0),
                      min: 0.7,
                      max: 2.0,
                      divisions: 26,
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
                      value: tempOffsetX.clamp(-100.0, 100.0),
                      min: -100.0,
                      max: 100.0,
                      divisions: 40,
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
                      value: tempOffsetY.clamp(-100.0, 100.0),
                      min: -100.0,
                      max: 100.0,
                      divisions: 40,
                      activeColor: AppColors.champagne,
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setModalState(() => tempOffsetY = v),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        provider.updateSlotAdjustment(
                          slotKey: currentSlot,
                          scale: tempScale,
                          offsetX: tempOffsetX,
                          offsetY: tempOffsetY,
                          shape: tempShape,
                          placement: tempPlacement,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF166534),
                            content: Text('$currentSlot framing & adjustments saved!'),
                            duration: const Duration(seconds: 2),
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
                        'Apply Adjustments to $currentSlot',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
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
                const SizedBox(height: 16),

                // 2. Photo Upload Section (Rendered ONLY if user selected With Photos AND template supports them)
                if (_isWithPhotos)
                  _buildPhotoUploadSection(provider, tmpl),

                // 3. Dynamic Text Elements from published Template Configuration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: AppColors.primaryGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Invitation Details',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (tmpl.textElements.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E28),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tmpl.textElements.length} fields',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.champagne,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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

                if (tmpl.textElements.isNotEmpty) ...[
                  ...tmpl.textElements.map((txtEl) {
                    final ctrl = _getControllerForElement(txtEl);
                    final isDate = txtEl.field.toLowerCase().contains('date');
                    final isTime = txtEl.field.toLowerCase().contains('time') ||
                        txtEl.field.toLowerCase().contains('muhurtham');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CustomTextField(
                        label: txtEl.label.isNotEmpty ? txtEl.label : txtEl.field,
                        hint: txtEl.defaultText.isNotEmpty
                            ? txtEl.defaultText
                            : 'Enter ${txtEl.label}',
                        controller: ctrl,
                        prefixIcon: _getIconForField(txtEl.field),
                        suffixIcon: isDate
                            ? IconButton(
                                icon: const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppColors.champagne),
                                onPressed: () => _pickDateForController(ctrl),
                              )
                            : isTime
                                ? IconButton(
                                    icon: const Icon(Icons.schedule_rounded,
                                        size: 18, color: AppColors.champagne),
                                    onPressed: () => _pickTimeForController(ctrl),
                                  )
                                : null,
                        onTap: () {
                          if (isDate && ctrl.text.trim().isEmpty) {
                            _pickDateForController(ctrl);
                          } else if (isTime && ctrl.text.trim().isEmpty) {
                            _pickTimeForController(ctrl);
                          }
                        },
                        validator: (v) {
                          if (txtEl.defaultText.isNotEmpty) {
                            return null; // Allows leaving empty to use the admin default placeholder
                          }
                          return (v == null || v.trim().isEmpty)
                              ? '${txtEl.label.isNotEmpty ? txtEl.label : txtEl.field} is required'
                              : null;
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ] else ...[
                // Bride Name (Required)
                CustomTextField(
                  label: "Bride's Name (పెళ్లికూతురు)",
                  hint: "e.g., Ananya",
                  controller: _brideController,
                  prefixIcon: Icons.woman_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Bride's name is required" : null,
                ),
                const SizedBox(height: 14),

                // Groom Name (Required)
                CustomTextField(
                  label: "Groom's Name (పెళ్లికొడుకు)",
                  hint: "e.g., Arjun",
                  controller: _groomController,
                  prefixIcon: Icons.man_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Groom's name is required" : null,
                ),
                const SizedBox(height: 14),

                // Wedding Date (Required)
                CustomTextField(
                  label: 'Wedding Date (తేదీ)',
                  hint: 'e.g., 28 November 2026',
                  controller: _dateController,
                  prefixIcon: Icons.calendar_month_rounded,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.champagne),
                    onPressed: () => _pickDate(context),
                  ),
                  onTap: () {
                    if (_dateController.text.trim().isEmpty) {
                      _pickDate(context);
                    }
                  },
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wedding date is required' : null,
                ),
                const SizedBox(height: 14),

                // Wedding Time / Muhurtham (Required)
                CustomTextField(
                  label: 'Wedding Time / Sumuhurtham (సుముహూర్తం)',
                  hint: 'e.g., 10:30 AM',
                  controller: _timeController,
                  prefixIcon: Icons.access_time_filled_rounded,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule_rounded, size: 18, color: AppColors.champagne),
                    onPressed: () => _pickTime(context),
                  ),
                  onTap: () {
                    if (_timeController.text.trim().isEmpty) {
                      _pickTime(context);
                    }
                  },
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wedding time is required' : null,
                ),
                const SizedBox(height: 14),

                // Wedding Venue (Required)
                CustomTextField(
                  label: 'Wedding Venue / Kalyana Mandapam (కల్యాణ మండపం)',
                  hint: 'e.g., Sri Convention Hall',
                  controller: _venueController,
                  prefixIcon: Icons.temple_hindu_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wedding venue is required' : null,
                ),
                const SizedBox(height: 14),

                // Wedding Location / Address
                CustomTextField(
                  label: 'Wedding Location / Address (చిరునామా)',
                  hint: 'e.g., Vijayawada',
                  controller: _addressController,
                  prefixIcon: Icons.location_on_rounded,
                ),
                const SizedBox(height: 14),

                // Parents' / Family names
                CustomTextField(
                  label: "Parents' or Family Names (తల్లిదండ్రుల ఆశీస్సులు)",
                  hint: 'e.g., Smt. Lakshmi & Sri. Rama Rao',
                  controller: _parentsController,
                  prefixIcon: Icons.family_restroom_rounded,
                ),
                const SizedBox(height: 14),

                // Additional Ceremony Details / RSVP
                CustomTextField(
                  label: 'Ceremony Title / Greetings (శుభకార్యం)',
                  hint: 'e.g., Subha Vivaham',
                  controller: _ceremonyController,
                  prefixIcon: Icons.celebration_rounded,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  label: 'RSVP / Cordial Welcome',
                  hint: 'e.g., With Best Wishes from Friends & Family',
                  controller: _rsvpController,
                  prefixIcon: Icons.mark_email_read_rounded,
                ),
                const SizedBox(height: 20),
              ],
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
