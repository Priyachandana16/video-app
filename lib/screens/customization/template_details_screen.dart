import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/video_player_widget.dart';
import 'personalization_form_screen.dart';

class TemplateDetailsScreen extends StatefulWidget {
  final TemplateModel template;

  const TemplateDetailsScreen({
    super.key,
    required this.template,
  });

  @override
  State<TemplateDetailsScreen> createState() => _TemplateDetailsScreenState();
}

class _TemplateDetailsScreenState extends State<TemplateDetailsScreen> {
  bool _showSampleResult = true;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

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

  Widget _buildTimelineStep(String time, String title, String description, {bool isChroma = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isChroma ? AppColors.emeraldChroma.withValues(alpha: 0.15) : AppColors.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isChroma ? AppColors.emeraldChroma : AppColors.primaryGold.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isChroma ? AppColors.emeraldChroma : AppColors.primaryGold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isChroma) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldChroma.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PHOTO KEY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emeraldChroma,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
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
    final template = widget.template;
    final isVertical = template.orientation == '9:16';
    final hasSample = template.sampleResultPath != null;
    final isChroma = template.id.contains('chroma');

    // Video source depending on toggle
    final activeVideoSource = (_showSampleResult && hasSample)
        ? template.sampleResultPath!
        : template.masterVideoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          template.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Mode Switcher (if sample result exists)
            if (hasSample) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.goldBorder, width: 0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showSampleResult = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: _showSampleResult ? AppColors.goldGradient : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: _showSampleResult ? AppColors.surfaceDark : AppColors.champagne,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Finished Sample Video',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _showSampleResult ? AppColors.surfaceDark : AppColors.champagne,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showSampleResult = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: !_showSampleResult ? AppColors.goldGradient : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isChroma ? Icons.video_camera_back : Icons.movie_outlined,
                                  size: 14,
                                  color: !_showSampleResult ? AppColors.surfaceDark : AppColors.champagne,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isChroma ? 'Raw Green Screen' : 'Master Template',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: !_showSampleResult ? AppColors.surfaceDark : AppColors.champagne,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Video Player Preview
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldBorder, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.goldGlow,
                      blurRadius: 18,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isVertical ? 400 : 230,
                    maxWidth: isVertical ? 250 : double.infinity,
                  ),
                  child: VideoPlayerWidget(
                    key: ValueKey(activeVideoSource),
                    videoSource: activeVideoSource,
                    isAsset: true,
                    aspectRatio: isVertical ? 9 / 16 : 16 / 9,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Metadata Row
            Row(
              children: [
                Expanded(
                  child: _buildMetaPill(
                    Icons.timer_outlined,
                    'Duration',
                    _formatDuration(template.durationSeconds),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetaPill(
                    isVertical ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                    'Resolution',
                    template.orientation == '16:9' ? '1920x1080' : '1080x1920',
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
            const SizedBox(height: 22),

            // About this template
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
            const SizedBox(height: 22),

            // Personalization Timeline Breakdown
            Text(
              'Video Scene Breakdown',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.champagne,
              ),
            ),
            const SizedBox(height: 12),

            if (template.id.contains('chroma')) ...[
              _buildTimelineStep('00:00 - 00:28', 'Lord Ganesha & Vedic Mantras', 'Traditional Sanskrit shloka with sacred bells and ceremonial bokeh.'),
              _buildTimelineStep('00:28 - 00:38', 'Bride Showcase (Auto Chroma Key)', 'Bride photo automatically composite-keyed into the golden mandapam arch.', isChroma: true),
              _buildTimelineStep('00:38 - 00:41', 'Sacred Mangalyam & Rings', 'Traditional wedding rings presentation and ceremonial transition.'),
              _buildTimelineStep('00:41 - 00:51', 'Couple Reveal (Auto Chroma Key)', 'Bride and Groom photo keyed into the auspicious mandapam.', isChroma: true),
              _buildTimelineStep('00:51 - 01:42', 'Muhurtham, Venue & Welcome', 'Sumuhurtham time, Kalyana Mandapam venue, and family cordial invitation.'),
            ] else if (template.id.contains('gold')) ...[
              _buildTimelineStep('00:00 - 00:15', 'Shree Rastu Shubhamastu', 'Golden diya lamp and authentic Nadaswaram wedding music invocation.'),
              _buildTimelineStep('00:15 - 00:30', 'Bride & Groom Names & Photos', 'Couple names revealed in royal gold with decorative floral arches.'),
              _buildTimelineStep('00:30 - 00:45', 'Sumuhurtham & Auspicious Lagna', 'Auspicious lagna time and date celebration slides.'),
              _buildTimelineStep('00:45 - 00:56', 'Venue & Cordial Family Welcome', 'Reception venue, directions, and cordial blessing wishes.'),
            ] else if (template.id.contains('divine')) ...[
              _buildTimelineStep('00:00 - 00:15', 'Divine Lord Ganesha Blessings', 'Glowing 3D golden Ganesha statue with floating celestial sparkles.'),
              _buildTimelineStep('00:15 - 00:35', 'Couple Names & Muhurtham Date', 'Traditional Telugu typography and wedding ceremony timing.'),
              _buildTimelineStep('00:35 - 00:59', 'Grand Palace Venue & Blessings', 'Venue address and family compliments with auspicious shlokas.'),
            ] else ...[
              _buildTimelineStep('00:00 - 00:03', 'Ceremony Intro', 'Auspicious wedding invitation opening.'),
              _buildTimelineStep('00:03 - 00:07', 'Couple Names', 'Groom & Bride names in gold typography.'),
              _buildTimelineStep('00:07 - 00:12', 'Muhurtham & Venue', 'Event timing, location, and RSVP.'),
            ],

            const SizedBox(height: 30),

            // CTA Button
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.goldGlow,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  context.read<PersonalizationProvider>().updateTemplate(template);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalizationFormScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_calendar_rounded, color: AppColors.surfaceDark, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Personalize This Video Invitation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.surfaceDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
