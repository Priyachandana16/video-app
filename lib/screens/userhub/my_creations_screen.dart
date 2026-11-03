import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/personalization_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/video_player_widget.dart';

class MyCreationsScreen extends StatelessWidget {
  const MyCreationsScreen({super.key});

  void _showPlayDialog(BuildContext context, String videoUrl, String title) {
    final isAsset = videoUrl.startsWith('assets/');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.primaryGold, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.champagne),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Container(
              height: 380,
              width: 240,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: VideoPlayerWidget(
                videoSource: videoUrl,
                isAsset: isAsset,
                aspectRatio: 9 / 16,
                autoPlay: true,
                looping: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalizationProvider>();
    final creations = provider.creations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Creations',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: provider.isLoadingCreations
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            )
          : creations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_collection_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Invitations Yet',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select any template from the Explore tab and personalize it with your details.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: creations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = creations[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.goldBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Thumbnail with play button overlay
                                GestureDetector(
                                  onTap: () => _showPlayDialog(context, item.videoUrl, item.title),
                                  child: Container(
                                    width: 80,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.primaryGold, width: 1),
                                      image: const DecorationImage(
                                        image: AssetImage('assets/candidate_chatgpt_jun.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.surfaceDark.withOpacity(0.8),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: AppColors.primaryGold,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.coupleNames,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.eventDate,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.champagne,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.venue,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.divider, height: 20),

                            // Actions Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final isAsset = item.videoUrl.startsWith('assets/');
                                    await StorageService.instance.saveVideoToDevice(
                                      videoSource: item.videoUrl,
                                      isAsset: isAsset,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: AppColors.emeraldFree,
                                          content: Text('Video saved to device storage.'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download_rounded, size: 16, color: AppColors.champagne),
                                  label: Text(
                                    'Download',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.champagne,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final isAsset = item.videoUrl.startsWith('assets/');
                                    StorageService.instance.shareVideo(
                                      videoSource: item.videoUrl,
                                      coupleTitle: item.coupleNames,
                                      isAsset: isAsset,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGold,
                                    foregroundColor: AppColors.surfaceDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.share_rounded, size: 16),
                                  label: Text(
                                    'Share',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
