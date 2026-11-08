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
  double _displayedProgress = 0.01;
  bool _hasStarted = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startRenderProcess();
  }

  void _startRenderProcess() async {
    if (_hasStarted && !_hasError) return;
    setState(() {
      _hasStarted = true;
      _hasError = false;
      _errorMessage = null;
      _displayedProgress = 0.01;
    });

    final provider = context.read<PersonalizationProvider>();
    final success = await provider.startRendering();

    if (mounted) {
      if (success) {
        setState(() => _displayedProgress = 1.0);
        // Allow brief visual confirmation of 100% completion
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VideoPreviewScreen(template: widget.template),
            ),
          );
        }
      } else {
        setState(() {
          _hasError = true;
          _hasStarted = false;
          _errorMessage = provider.renderError ??
              'Video generation encountered an issue. Please try again.';
        });
      }
    }
  }

  String _getStepLabel(PersonalizationProvider provider, double progress) {
    if (provider.renderStep.isNotEmpty &&
        provider.renderStep != 'Preparing your invitation...') {
      return provider.renderStep;
    }
    if (progress < 0.15) return 'Preparing your invitation...';
    if (progress < 0.35) return 'Processing wedding details...';
    if (progress < 0.55) {
      return provider.data.hasPhoto
          ? 'Preparing uploaded photos...'
          : 'Composing sacred typography & animations...';
    }
    if (progress < 0.75) return 'Creating invitation scenes...';
    if (progress < 0.95) return 'Rendering your invitation video...';
    if (progress < 1.0) return 'Finalizing video...';
    return 'Video ready!';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final rawTarget = provider.renderProgress;

    // Enforce monotonic forward progress starting from 0.01 up to 1.0
    final targetProgress = _hasError
        ? _displayedProgress
        : rawTarget.clamp(_displayedProgress, 1.0);

    return PopScope(
      canPop: _hasError,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E12),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: _hasError
                  ? _buildErrorView()
                  : TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: _displayedProgress,
                        end: targetProgress,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      onEnd: () {
                        if (targetProgress > _displayedProgress) {
                          _displayedProgress = targetProgress;
                        }
                      },
                      builder: (context, animValue, _) {
                        final currentVal = animValue.clamp(0.01, 1.0);
                        final displayPercent = (currentVal * 100).toInt().clamp(1, 100);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular Progress Indicator
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Subtle gold circular track border
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryGold
                                          .withValues(alpha: 0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Animated Circular Progress Indicator
                                SizedBox(
                                  width: 116,
                                  height: 116,
                                  child: CircularProgressIndicator(
                                    value: currentVal,
                                    strokeWidth: 4.5,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: const Color(0xFF1E1E28),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryGold,
                                    ),
                                  ),
                                ),
                                // Centered Percentage Display
                                Text(
                                  '$displayPercent%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Heading
                            Text(
                              'Crafting Royal Invitation',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dynamic Stage Label
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _getStepLabel(provider, currentVal),
                                key: ValueKey(provider.renderStep),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.champagne,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF18151A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE11D48).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFB7185),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Generation Interrupted',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ??
                'We could not finalize the video. Your custom details and photos are safely preserved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFFCBD5E1),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Back to Edit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startRenderProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Retry Generation',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
