import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'auth/sign_in_screen.dart';
import 'home/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    _navTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final targetScreen = auth.isAuthenticated
            ? const MainNavigationScreen()
            : const SignInScreen();

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, _, _) => targetScreen,
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryGold.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // Central Branding Content with Official Logo
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Logo displaying full emblem, pink-and-gold lettering, hearts, and Telugu tagline
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Image.asset(
                        'assets/official_logo.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Elegant Gold & Pink Accent Spinner
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Version Badge
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0 • Made with Precision',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
