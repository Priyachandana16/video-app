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
  String? _savedPath;

  void _handleDownload() async {
    setState(() => _isSaving = true);
    final provider = context.read<PersonalizationProvider>();
    final path = await provider.downloadToDevice();
    setState(() {
      _isSaving = false;
      _savedPath = path;
    });

    if (mounted) {
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
              const Icon(Icons.check_circle_rounded, color: AppColors.emeraldFree, size: 28),
              const SizedBox(width: 10),
              Text(
                'Video Saved!',
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
                'Your royal invitation MP4 has been successfully saved to your Android device.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldBorder, width: 0.8),
                ),
                child: Text(
                  path ?? '/storage/emulated/0/Download/My_Invitation.mp4',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.champagne,
                  ),
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
    final videoPath = provider.renderedVideoUrl ?? 'assets/personalized_output.mp4';
    final isAsset = videoPath.startsWith('assets/');

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Preview Invitation',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldFree.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emeraldFree.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: AppColors.emeraldFree, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ready For Download & Sharing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.emeraldFree,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Text(
                '${data.coupleTitle} ${data.ceremonyTitle}',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.eventDate} • ${data.muhurthamTime}',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.champagne,
                ),
              ),
              const SizedBox(height: 16),

              // Video Player
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isVertical ? 390 : 230,
                  maxWidth: isVertical ? 240 : double.infinity,
                ),
                child: VideoPlayerWidget(
                  videoSource: videoPath,
                  isAsset: isAsset,
                  aspectRatio: isVertical ? 9 / 16 : 16 / 9,
                  autoPlay: true,
                  looping: true,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              CustomButton(
                text: _isSaving ? 'Saving to Device...' : 'Save Video to Phone',
                icon: Icons.download_rounded,
                isLoading: _isSaving,
                onPressed: _handleDownload,
              ),
              const SizedBox(height: 12),

              CustomButton(
                text: 'Share via WhatsApp / Socials',
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
