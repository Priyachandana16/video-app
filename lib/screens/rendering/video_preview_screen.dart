import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/template_model.dart';
import '../../providers/personalization_provider.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/custom_button.dart';
import '../home/main_navigation_screen.dart';

class VideoPreviewScreen extends StatefulWidget {
  final TemplateModel template;

  const VideoPreviewScreen({
    super.key,
    required this.template,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  bool _isSaving = false;
  int _previewSeconds = 10;
  bool _previewCompleted = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startPreviewTimer();
  }

  void _startPreviewTimer() {
    _countdownTimer?.cancel();
    _previewSeconds = 10;
    _previewCompleted = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_previewSeconds > 1) {
        setState(() {
          _previewSeconds--;
        });
      } else {
        setState(() {
          _previewSeconds = 0;
          _previewCompleted = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleDownload() async {
    setState(() => _isSaving = true);
    final provider = context.read<PersonalizationProvider>();
    final success = await provider.downloadToDevice();
    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primaryGold, width: 1),
          ),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: success ? AppColors.emeraldChroma : AppColors.primaryGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Video downloaded directly to your device!'
                      : 'Download initiated. Please check your Downloads folder.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryGold, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.emeraldChroma, size: 28),
              const SizedBox(width: 10),
              Text(
                'Video Downloaded',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your invitation video is saved directly to your device storage in full original HD quality.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldBorder, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.file_download_done_rounded, color: AppColors.primaryGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stored in Downloads • 1080p MP4 Format',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.champagne,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Done',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _handleShare() {
    final provider = context.read<PersonalizationProvider>();
    provider.shareRenderedVideo();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final data = provider.data;
    final isVertical = widget.template.orientation == '9:16';
    final videoPath = provider.renderedVideoUrl ??
        (widget.template.sampleResultPath ?? 'assets/templates/template_01_sample_result.mp4');
    final isAsset = videoPath.startsWith('assets/');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Invitation Video Preview',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.home_rounded, color: AppColors.primaryGold),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 10-Second Preview Status Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _previewCompleted
                      ? AppColors.emeraldChroma.withValues(alpha: 0.15)
                      : AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _previewCompleted
                        ? AppColors.emeraldChroma.withValues(alpha: 0.5)
                        : AppColors.primaryGold.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _previewCompleted ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                      color: _previewCompleted ? AppColors.emeraldChroma : AppColors.primaryGold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _previewCompleted
                          ? '10-Second In-App Preview Finished • Full HD Quality'
                          : 'In-App Video Preview: ${_previewSeconds}s remaining',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _previewCompleted ? AppColors.emeraldChroma : AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),

              // Preview Progress Line
              if (!_previewCompleted) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (10 - _previewSeconds) / 10.0,
                      minHeight: 4,
                      backgroundColor: AppColors.cardSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Title Header
              if (data.coupleTitle.isNotEmpty || data.ceremonyTitle.isNotEmpty)
                Text(
                  '${data.coupleTitle} ${data.ceremonyTitle}'.trim(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
              if (data.eventDate.isNotEmpty || data.venue.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [data.eventDate, data.muhurthamTime, data.venue].where((s) => s.isNotEmpty).join(' • '),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.champagne,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Video Player directly in-app
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.goldGlow,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isVertical ? 400 : 240,
                    maxWidth: isVertical ? 250 : double.infinity,
                  ),
                  child: VideoPlayerWidget(
                    videoSource: videoPath,
                    isAsset: isAsset,
                    aspectRatio: isVertical ? 9 / 16 : 16 / 9,
                    autoPlay: true,
                    looping: true,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Download Video Option
              CustomButton(
                text: _isSaving
                    ? 'Saving to Device...'
                    : (_previewCompleted
                        ? 'Download Video (Full HD MP4)'
                        : 'Download Video (${_previewSeconds}s preview)'),
                icon: Icons.download_rounded,
                isLoading: _isSaving,
                onPressed: _handleDownload,
              ),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Share on WhatsApp & Socials',
                icon: Icons.share_rounded,
                type: ButtonType.outlined,
                onPressed: _handleShare,
              ),
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 1)),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.video_library_outlined, color: AppColors.champagne, size: 18),
                label: Text(
                  'View in My Creations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.champagne,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
