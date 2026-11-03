import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoDownload = true;
  bool _highBitrate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Video Export Preferences',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.champagne,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.goldBorder, width: 0.8),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: AppColors.primaryGold,
                  title: Text(
                    'Auto-Save to MediaStore',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically copy generated MP4 to phone gallery',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _autoDownload,
                  onChanged: (val) => setState(() => _autoDownload = val),
                ),
                const Divider(color: AppColors.divider, height: 1),
                SwitchListTile(
                  activeColor: AppColors.primaryGold,
                  title: Text(
                    'High Bitrate Render (30fps)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Preserve highest audio fidelity and sharp typography',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _highBitrate,
                  onChanged: (val) => setState(() => _highBitrate = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Legal & Information',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.champagne,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.goldBorder, width: 0.8),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'License & Open Source Assets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'All template videos & audio are royalty-free licensed for personal use',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.verified_outlined, color: AppColors.emeraldFree, size: 20),
                ),
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  title: Text(
                    'Clear Temporary Video Cache',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.cleaning_services_outlined, color: AppColors.champagne, size: 20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.emeraldFree,
                        content: Text('Temporary render cache cleared.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
