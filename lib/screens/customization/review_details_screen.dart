import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/custom_button.dart';
import '../rendering/video_processing_screen.dart';

class ReviewDetailsScreen extends StatelessWidget {
  final TemplateModel template;

  const ReviewDetailsScreen({
    super.key,
    required this.template,
  });

  Widget _buildSummaryRow(String label, String value, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isGold ? AppColors.primaryGold : AppColors.textPrimary,
              ),
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
          'Review Invitation',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couple Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primaryGold, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (template.hasPhoto) ...[
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGold, width: 2),
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
                    const SizedBox(height: 14),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_stories_outlined, color: AppColors.primaryGold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Traditional Photo-Free Vedic Vivaham',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.champagne,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    data.ceremonyTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.champagne,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.coupleTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  if (data.parentsNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      data.parentsNames,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detailed Breakdown Card
            Text(
              'Ceremony Information',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.champagne,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.goldBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Template', template.title),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildSummaryRow('Photo Option', template.hasPhoto ? 'With Photo (Couple Portrait)' : 'Without Photo (Traditional Vedic)'),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildSummaryRow('Tradition', template.religion),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildSummaryRow('Format', '${template.orientation} Vertical Video'),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildSummaryRow('Auspicious Date', data.eventDate, isGold: true),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildSummaryRow('Muhurtham', data.muhurthamTime, isGold: true),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildSummaryRow('Venue', data.venue),
                  if (data.rsvp.isNotEmpty) ...[
                    const Divider(color: AppColors.divider, height: 16),
                    _buildSummaryRow('RSVP', data.rsvp),
                  ],
                  if (data.contactPhone.isNotEmpty) ...[
                    const Divider(color: AppColors.divider, height: 16),
                    _buildSummaryRow('Contact', data.contactPhone),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Free Direct Generation Notice (No Payment Gate!)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emeraldFree.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emeraldFree.withOpacity(0.4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.emeraldFree, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Free Instant HD Render • No payment or watermarks required.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emeraldFree,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.goldBorder, width: 1)),
        ),
        child: SafeArea(
          child: CustomButton(
            text: provider.isRendering ? 'Rendering In Progress...' : 'Generate Royal Video',
            icon: Icons.movie_creation_outlined,
            isLoading: provider.isRendering,
            onPressed: provider.isRendering
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoProcessingScreen(template: template),
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }
}
