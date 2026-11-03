import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/template_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TemplateProvider>();

    final categories = [
      {
        'title': 'Hindu Traditions',
        'subtitle': 'Shubh Vivah • Kalyanam • Telugu Vivaham',
        'religion': 'Hindu',
        'image': 'assets/candidate_chatgpt_jun.png',
        'count': '18+ Designs',
      },
      {
        'title': 'Christian Matrimony',
        'subtitle': 'Cathedral Vows • Garden Elegance',
        'religion': 'Christian',
        'image': 'assets/pic16.png',
        'count': '12+ Designs',
      },
      {
        'title': 'Muslim Nikah',
        'subtitle': 'Noor-e-Nikah • Emerald Arches',
        'religion': 'Muslim',
        'image': 'assets/meshy1.png',
        'count': '10+ Designs',
      },
      {
        'title': 'Widescreen 16:9 Panoramas',
        'subtitle': 'LED Wall & TV Projection Videos',
        'orientation': '16:9',
        'image': 'assets/meshy2.png',
        'count': '8+ Designs',
      },
      {
        'title': 'Evening Receptions',
        'subtitle': 'Fireworks • Royal Banquet Gala',
        'category': 'Reception',
        'image': 'assets/meshy3.png',
        'count': '14+ Designs',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Traditions & Categories',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final cat = categories[index];

          return GestureDetector(
            onTap: () {
              if (cat['religion'] != null) {
                provider.setReligion(cat['religion']!);
              } else if (cat['orientation'] != null) {
                provider.applyFilters(
                  religion: 'All',
                  orientation: cat['orientation']!,
                  photoFilter: 'All',
                );
              } else if (cat['category'] != null) {
                provider.setCategory(cat['category']!);
              }
              Navigator.pop(context);
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldBorder, width: 1.2),
                image: DecorationImage(
                  image: AssetImage(cat['image']!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            cat['title']!,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat['subtitle']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.champagne,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['count']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primaryGold,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
