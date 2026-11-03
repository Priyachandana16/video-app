import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/template_provider.dart';
import 'providers/personalization_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style to match midnight obsidian luxury theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
      ],
      child: const MyInvitationApp(),
    ),
  );
}

class MyInvitationApp extends StatelessWidget {
  const MyInvitationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Invitation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return Container(
          color: const Color(0xFF060608),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child!,
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
