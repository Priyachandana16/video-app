import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/custom_button.dart';
import 'personalization_form_screen.dart';

class TemplateDetailsScreen extends StatelessWidget {
  final TemplateModel template;

  const TemplateDetailsScreen({
    super.key,
    required this.template,
  });

  Widget _buildMetaPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.champagne),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String time, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.4), width: 0.8),
            ),
            child: Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGold,
              ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = template.orientation == '9:16';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          template.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Preview
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isVertical ? 380 : 220,
                  maxWidth: isVertical ? 240 : double.infinity,
                ),
                child: VideoPlayerWidget(
                  videoSource: template.masterVideoPath,
                  isAsset: true,
                  aspectRatio: isVertical ? 9 / 16 : 16 / 9,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Metadata Row
            Row(
              children: [
                Expanded(
                  child: _buildMetaPill(
                    Icons.timer_outlined,
                    'Duration',
                    '0:${template.durationSeconds}s',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetaPill(
                    isVertical ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                    'Format',
                    template.orientation,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetaPill(
                    Icons.photo_library_outlined,
                    'Photos',
                    template.hasPhoto ? '${template.photoSlotsCount} Slots' : 'None',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Template Story & Description
            Text(
              'About this invitation',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.champagne,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Personalization Timeline Breakdown
            Text(
              'Personalization Timeline',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.champagne,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.goldBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTimelineStep('0–3s', 'Ceremonial Intro', 'Auspicious background music & invocation title'),
                  _buildTimelineStep('3–6.5s', 'Couple Names', 'Bride & groom names with elegant gold typography'),
                  if (template.hasPhoto)
                    _buildTimelineStep('6.5–9.5s', 'Couple Photo', 'Your uploaded photo in circular gold frame')
                  else
                    _buildTimelineStep('6.5–9.5s', 'Auspicious Blessing', 'Family & parent names announcement'),
                  _buildTimelineStep('9.5–12s', 'Event & Venue', 'Muhurtham date, time, location & RSVP details'),
                ],
              ),
            ),
            const SizedBox(height: 100), // Spacing for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: const Border(top: BorderSide(color: AppColors.goldBorder, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: 'Personalize This Video',
            icon: Icons.edit_note_rounded,
            onPressed: () {
              context.read<PersonalizationProvider>().updateTemplateId(template.id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PersonalizationFormScreen(template: template),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
