import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

enum ButtonType { primary, secondary, outlined }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.height = 54,
    this.borderRadius = 16,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = type == ButtonType.primary;
    final isOutlined = type == ButtonType.outlined;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPrimary && onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? AppColors.primaryGold
              : isOutlined
                  ? Colors.transparent
                  : AppColors.cardSurface,
          foregroundColor: isPrimary ? AppColors.surfaceDark : AppColors.champagne,
          disabledBackgroundColor: AppColors.surfaceHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isOutlined
                ? const BorderSide(color: AppColors.primaryGold, width: 1.2)
                : BorderSide(
                    color: isPrimary ? Colors.transparent : AppColors.goldBorder,
                    width: 1,
                  ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: isPrimary ? AppColors.surfaceDark : AppColors.primaryGold,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
