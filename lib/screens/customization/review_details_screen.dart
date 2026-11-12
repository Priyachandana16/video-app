import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/custom_button.dart';
import '../rendering/video_processing_screen.dart';

class ReviewDetailsScreen extends StatelessWidget {
  final TemplateModel template;
  final bool? hasPhoto;

  const ReviewDetailsScreen({
    super.key,
    required this.template,
    this.hasPhoto,
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
                color: const Color(0xFF94A3B8),
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
                color: isGold ? const Color(0xFFEAB308) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview({
    required String label,
    required String sceneTime,
    String? localPath,
    Uint8List? bytes,
  }) {
    final hasBytes = bytes != null;
    final hasPath = localPath != null && localPath.isNotEmpty;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF16161C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAB308), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                blurRadius: 10,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasBytes
              ? Image.memory(bytes, fit: BoxFit.cover)
              : (hasPath && !kIsWeb
                  ? Image.file(File(localPath), fit: BoxFit.cover)
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline_rounded, color: Colors.white38, size: 36),
                          SizedBox(height: 4),
                          Text('No Photo', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    )),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          sceneTime,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: const Color(0xFFEAB308),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final data = provider.data;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E12),
        elevation: 0,
        title: Text(
          'Review Invitation',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Template Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF16161E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      template.thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFF262632),
                        child: const Icon(Icons.videocam, color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFEAB308),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ceremony Photo Placements (Rendered ONLY if user selected With Photos)
            if ((hasPhoto ?? template.hasPhoto) && data.hasPhoto) ...[
              Text(
                'Ceremony Photo Placements',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Photos will appear at these exact timeframes in the template video:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 14),

              if (template.imageElements.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: template.imageElements.map((imgEl) {
                    final slotKey = imgEl.field;
                    final slotBytes = data.getSlotPhotoBytes(slotKey);
                    final slotPath = data.getSlotPhotoPath(slotKey);
                    final animName = imgEl.animationType == 'ink_reveal'
                        ? 'Ink Reveal'
                        : imgEl.animationType == 'brush_stroke'
                            ? 'Brush Stroke'
                            : 'Fade';

                    return _buildPhotoPreview(
                      label: imgEl.label.isNotEmpty ? imgEl.label : slotKey,
                      sceneTime: '$animName (${imgEl.startTime.toInt()}s - ${imgEl.endTime.toInt()}s)',
                      localPath: slotPath,
                      bytes: slotBytes,
                    );
                  }).toList(),
                )
              else if (template.photoSlotsCount > 2)
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: List.generate(template.photoSlotsCount, (index) {
                    final slotKey = 'photo_${index + 1}';
                    final slotBytes = data.getSlotPhotoBytes(slotKey);
                    final slotPath = data.getSlotPhotoPath(slotKey);
                    final defaultLabel = index == 0
                        ? "Groom's Photo"
                        : index == 1
                            ? "Bride's Photo"
                            : "Photo ${index + 1}";
                    return _buildPhotoPreview(
                      label: defaultLabel,
                      sceneTime: 'Slot ${index + 1}',
                      localPath: slotPath,
                      bytes: slotBytes,
                    );
                  }),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPhotoPreview(
                      label: 'Woman Photo',
                      sceneTime: 'Scene 2: 00:28 - 00:38',
                      localPath: data.womanPhotoPath,
                      bytes: data.womanPhotoBytes,
                    ),
                    _buildPhotoPreview(
                      label: 'Man Photo',
                      sceneTime: 'Scene 3: 00:41 - 00:51',
                      localPath: data.manPhotoPath,
                      bytes: data.manPhotoBytes,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],

            // Ceremony Information Card
            Text(
              'Invitation Details',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
              ),
              child: Column(
                children: template.textElements.isNotEmpty
                    ? template.textElements.map((txtEl) {
                        final val = data.getCustomText(txtEl.field, fallback: txtEl.defaultText);
                        final isGold = txtEl.field.toLowerCase().contains('title') ||
                            txtEl.field.toLowerCase().contains('muhurtham');
                        return _buildSummaryRow(
                          txtEl.label.isNotEmpty ? txtEl.label : txtEl.field,
                          val,
                          isGold: isGold,
                        );
                      }).toList()
                    : [
                        _buildSummaryRow('Groom (పెళ్లికొడుకు)', data.groomName),
                        _buildSummaryRow('Bride (పెళ్లికూతురు)', data.brideName),
                        _buildSummaryRow('Ceremony', data.ceremonyTitle, isGold: true),
                        _buildSummaryRow('Parents Blessings', data.parentsNames),
                        _buildSummaryRow('Date (తేదీ)', data.eventDate),
                        _buildSummaryRow('Muhurtham', data.muhurthamTime, isGold: true),
                        _buildSummaryRow('Mandapam Venue', data.venue),
                        _buildSummaryRow('RSVP', data.rsvp),
                      ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm & Generate Action
            CustomButton(
              text: 'Generate Royal Video Invitation',
              icon: Icons.movie_creation_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoProcessingScreen(template: template),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
