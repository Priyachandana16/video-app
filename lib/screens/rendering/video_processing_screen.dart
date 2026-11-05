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

  String _getStepLabel(PersonalizationProvider provider) {
    if (provider.renderStep.isNotEmpty &&
        !provider.renderStep.startsWith('Loading master video')) {
      return provider.renderStep;
    }
    final progress = provider.renderProgress;
    final isChroma = widget.template.id.contains('chroma');
    if (progress < 0.20) return 'Loading master HD video & Nadaswaram audio...';
    if (progress < 0.45) return isChroma ? 'Executing Chroma-Key Mandap Arch Detection...' : 'Compositing golden typography & details...';
    if (progress < 0.70) return isChroma ? 'Compositing Photo into Chroma Window...' : 'Framing personalized photo with royal filigree...';
    if (progress < 0.90) return 'Applying auspicious Muhurtham & Vedic fonts...';
    return 'Finalizing 1080p H.264 MP4 with synchronized audio...';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final progress = provider.renderProgress;

    return PopScope(
      canPop: false,
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
                            color: AppColors.primaryGold.withValues(alpha: 0.25),
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
                  'Crafting Royal Invitation',
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
                  _getStepLabel(provider),
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
                      const Icon(Icons.auto_awesome, color: AppColors.primaryGold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.template.id.contains('chroma')
                              ? 'Chroma Key engine is blending your photo seamlessly into the golden mandap arch.'
                              : 'Personalized with your couple name, photo, and event Muhurtham.',
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
