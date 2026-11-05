import 'package:flutter/material.dart';

class AppColors {
  // Base obsidian backgrounds
  static const Color background = Color(0xFF09090D);
  static const Color surfaceDark = Color(0xFF101015);
  static const Color cardSurface = Color(0xFF15151D);
  static const Color elevatedSurface = Color(0xFF1B1B24);
  static const Color surfaceHigh = Color(0xFF23232E);

  // Brand Pink & Gold Luxury Palette (matching official logo)
  static const Color brandPink = Color(0xFFE91E63);
  static const Color brandVividPink = Color(0xFFFF2A7A);
  static const Color brandDeepPink = Color(0xFFC2185B);
  static const Color brandPinkGlow = Color(0x40E91E63);
  static const Color brandPinkBorder = Color(0x4DE91E63);

  // 24K Gold & Champagne luxury palette
  static const Color primaryGold = Color(0xFFF5B82E);
  static const Color richGold = Color(0xFFFFD56B);
  static const Color deepGold = Color(0xFFC8931F);
  static const Color champagne = Color(0xFFF6D98B);
  static const Color goldDim = Color(0xFFE0C478);
  static const Color goldBorder = Color(0x3DF5B82E); // 24% gold border
  static const Color goldGlow = Color(0x59F5B82E);

  // Ceremonial & Accent roles
  static const Color royalCrimson = Color(0xFF8B1E32);
  static const Color crimsonGlow = Color(0x408B1E32);
  static const Color emeraldChroma = Color(0xFF10B981);
  static const Color emeraldFree = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x4010B981);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFFE6E3EB);
  static const Color textSecondary = Color(0xFFAAA6B8);
  static const Color textMuted = Color(0xFF706F7E);

  // Interactive
  static const Color divider = Color(0x1FFFFFFF);
  static const Color inputBackground = Color(0xFF13131A);
  static const Color inputBorder = Color(0x33F5B82E);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFDF7D), Color(0xFFF5B82E), Color(0xFFD49718)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF191924), Color(0xFF13131A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0x33F5B82E), Color(0x108B1E32), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
