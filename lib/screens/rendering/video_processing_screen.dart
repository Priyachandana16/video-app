import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import 'video_preview_screen.dart';

class VideoProcessingScreen extends StatefulWidget {
  final TemplateModel template;

  const VideoProcessingScreen({
    super.key,
    required this.template,
  });

  @override
  State<VideoProcessingScreen> createState() => _VideoProcessingScreenState();
}

class _VideoProcessingScreenState extends State<VideoProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _startRenderProcess();
  }

  void _startRenderProcess() async {
    final provider = context.read<PersonalizationProvider>();
    final success = await provider.startRendering();

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VideoPreviewScreen(template: widget.template),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.royalCrimson,
            content: Text(
              provider.renderError ?? 'Video generation error',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  String _getStepLabel(double progress) {
    if (progress < 0.25) return 'Loading master invitation template...';
    if (progress < 0.55) return 'Compositing names & typography...';
    if (progress < 0.85) return 'Masking couple photo into gold frame...';
    return 'Finalizing 720p 30fps MP4 invitation...';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final progress = provider.renderProgress;

    return WillPopScope(
      onWillPop: () async => false, // Prevent accidental back press during render
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Gold Spinner Container
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 4,
                        backgroundColor: AppColors.surfaceHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Processing Title
                Text(
                  'Rendering Royal Invitation',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Current Step
                Text(
                  _getStepLabel(progress),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.champagne,
                  ),
                ),
                const SizedBox(height: 28),

                // Information Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.goldBorder, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryGold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Personalized with your couple name, photo, and event Muhurtham.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
