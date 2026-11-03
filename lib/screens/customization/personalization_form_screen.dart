import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'review_details_screen.dart';

class PersonalizationFormScreen extends StatefulWidget {
  final TemplateModel template;

  const PersonalizationFormScreen({
    super.key,
    required this.template,
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
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final p = context.read<PersonalizationProvider>().data;

    // Set default ceremony title based on religion
    String defaultCeremony = 'Shubh Vivaham';
    if (widget.template.religion == 'Christian') {
      defaultCeremony = 'Holy Matrimony';
    } else if (widget.template.religion == 'Muslim') {
      defaultCeremony = 'Nikah Mubarak';
    }

    _groomController = TextEditingController(text: p.groomName.isNotEmpty ? p.groomName : 'Rajesh');
    _brideController = TextEditingController(text: p.brideName.isNotEmpty ? p.brideName : 'Ananya');
    _ceremonyController = TextEditingController(text: defaultCeremony);
    _parentsController = TextEditingController(text: p.parentsNames);
    _dateController = TextEditingController(text: p.eventDate);
    _timeController = TextEditingController(text: p.muhurthamTime);
    _venueController = TextEditingController(text: p.venue);
    _rsvpController = TextEditingController(text: p.rsvp);
    _phoneController = TextEditingController(text: p.contactPhone);
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
    _phoneController.dispose();
    super.dispose();
  }

  void _saveFormAndProceed() {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<PersonalizationProvider>();
      provider.updateForm(
        groomName: _groomController.text.trim(),
        brideName: _brideController.text.trim(),
        ceremonyTitle: _ceremonyController.text.trim(),
        parentsNames: _parentsController.text.trim(),
        eventDate: _dateController.text.trim(),
        muhurthamTime: _timeController.text.trim(),
        venue: _venueController.text.trim(),
        rsvp: _rsvpController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        hasPhoto: widget.template.hasPhoto,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewDetailsScreen(template: widget.template),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.champagne,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final data = provider.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Personalize Invitation',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Section (if template supports photo)
              if (widget.template.hasPhoto) ...[
                _buildSectionTitle('Couple Photograph', Icons.photo_camera_outlined),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.goldBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => provider.pickPrimaryPhoto(),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.inputBackground,
                            border: Border.all(color: AppColors.primaryGold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withOpacity(0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (data.primaryPhotoBytes != null)
                              ? Image.memory(
                                  data.primaryPhotoBytes!,
                                  fit: BoxFit.cover,
                                )
                              : (!kIsWeb && data.primaryPhotoPath != null)
                                  ? Image.file(
                                      File(data.primaryPhotoPath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/candidate_chatgpt_jun.png',
                                      fit: BoxFit.cover,
                                    ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (data.primaryPhotoBytes != null || data.primaryPhotoPath != null)
                                  ? 'Custom Photo Selected'
                                  : 'Sample Couple Photo Active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap circle to select your high-res couple photo from gallery',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => provider.pickPrimaryPhoto(),
                              child: Text(
                                'Change Photo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Couple Details
              _buildSectionTitle('Couple Details', Icons.favorite_border_rounded),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Groom Name',
                      hint: 'Rajesh',
                      controller: _groomController,
                      prefixIcon: Icons.male_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Bride Name',
                      hint: 'Ananya',
                      controller: _brideController,
                      prefixIcon: Icons.female_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Ceremony Headline',
                hint: 'e.g. Shubh Vivaham / Holy Matrimony',
                controller: _ceremonyController,
                prefixIcon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Parents & Hosts (Optional)',
                hint: 'e.g. Smt. Lakshmi & Sri. Venkat Rao',
                controller: _parentsController,
                prefixIcon: Icons.family_restroom_rounded,
              ),
              const SizedBox(height: 14),

              // Event Schedule
              _buildSectionTitle('Event Schedule', Icons.calendar_month_outlined),
              CustomTextField(
                label: 'Auspicious Date',
                hint: 'e.g. Sunday, 15 December 2026',
                controller: _dateController,
                prefixIcon: Icons.event,
                validator: (val) => val == null || val.isEmpty ? 'Date is required' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Muhurtham / Ceremony Time',
                hint: 'e.g. Muhurtham: 09:45 AM',
                controller: _timeController,
                prefixIcon: Icons.access_time_rounded,
                validator: (val) => val == null || val.isEmpty ? 'Time is required' : null,
              ),
              const SizedBox(height: 14),

              // Venue
              _buildSectionTitle('Venue & Location', Icons.location_on_outlined),
              CustomTextField(
                label: 'Venue Address',
                hint: 'The Grand Chola Palace, Guindy, Chennai',
                controller: _venueController,
                prefixIcon: Icons.place_rounded,
                maxLines: 2,
                validator: (val) => val == null || val.isEmpty ? 'Venue is required' : null,
              ),
              const SizedBox(height: 14),

              // RSVP
              _buildSectionTitle('RSVP & Blessings', Icons.phone_outlined),
              CustomTextField(
                label: 'RSVP Note',
                hint: 'With Best Compliments from Family & Friends',
                controller: _rsvpController,
                prefixIcon: Icons.rate_review_outlined,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Contact Phone Number',
                hint: '+91 98765 43210',
                controller: _phoneController,
                prefixIcon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: const Border(top: BorderSide(color: AppColors.goldBorder, width: 1)),
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Review & Continue',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _saveFormAndProceed,
          ),
        ),
      ),
    );
  }
}
