import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/template_model.dart';

class TemplateCard extends StatelessWidget {
  final TemplateModel template;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  ImageProvider _resolveImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    if (url.startsWith('/assets/')) {
      return NetworkImage('http://localhost:5000$url');
    }
    return AssetImage(url);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = template.orientation == '9:16';
    final isChroma = template.id.contains('chroma') || template.badgeText.contains('CHROMA');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isChroma ? AppColors.emeraldChroma.withValues(alpha: 0.6) : AppColors.goldBorder,
            width: isChroma ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isChroma
                  ? AppColors.emeraldGlow
                  : Colors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Thumbnail Header
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: isVertical ? 16 / 10 : 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      image: DecorationImage(
                        image: _resolveImage(template.thumbnailUrl),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Left Badges: Chroma / Premium Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: isChroma
                              ? const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                )
                              : AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: isChroma ? AppColors.emeraldGlow : AppColors.goldGlow,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isChroma) ...[
                              const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              template.badgeText.isNotEmpty ? template.badgeText : 'PREMIUM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isChroma ? Colors.white : AppColors.surfaceDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Right Orientation Pill
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.goldBorder, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVertical ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                          size: 13,
                          color: AppColors.champagne,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          template.orientation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.champagne,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center Play Button with subtle breathing ring
                Positioned.fill(
                  child: Center(
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceDark.withValues(alpha: 0.75),
                        border: Border.all(
                          color: isChroma ? AppColors.emeraldChroma : AppColors.primaryGold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isChroma ? AppColors.emeraldGlow : AppColors.goldGlow,
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: isChroma ? AppColors.emeraldChroma : AppColors.primaryGold,
                        size: 34,
                      ),
                    ),
                  ),
                ),

                // Bottom Overlay Badges (Duration & Photo Slot Count)
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: AppColors.champagne),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(template.durationSeconds),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.champagne,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: template.hasPhoto
                              ? AppColors.royalCrimson.withValues(alpha: 0.85)
                              : Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: template.hasPhoto ? AppColors.champagne : Colors.white12,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              template.hasPhoto ? Icons.photo_camera_rounded : Icons.photo_outlined,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              template.hasPhoto
                                  ? (isChroma ? 'Chroma Photo Swap' : '${template.photoSlotsCount} Photos')
                                  : 'Text Only',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.goldBorder, width: 0.8),
                        ),
                        child: Text(
                          template.religion,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.champagne,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        template.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (isChroma)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldChroma.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI Chroma',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emeraldChroma,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Bottom CTA Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            gradient: isChroma
                                ? const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                                  )
                                : AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: isChroma ? AppColors.emeraldGlow : AppColors.goldGlow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.surfaceDark),
                                const SizedBox(width: 6),
                                Text(
                                  'Personalize This Video',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.surfaceDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
