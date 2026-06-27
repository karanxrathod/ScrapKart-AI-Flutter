import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/animated_blob_background.dart';
import '../../services/local_db_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final isLoggedIn = await LocalDbService.instance.isUserLoggedIn();
    if (!mounted) return;
    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBlobBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Logo Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
              ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack)
               .fadeIn(duration: 600.ms),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                'ScrapKart AI',
                style: AppTextStyles.headline.copyWith(
                  fontSize: 36,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ).animate().slideY(begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOutQuad)
               .fadeIn(delay: 200.ms),
              
              const SizedBox(height: 12),
              
              // Tagline
              Text(
                'Smart Waste Intelligence',
                style: AppTextStyles.subtitle.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ).animate().slideY(begin: 1.0, end: 0, duration: 600.ms, delay: 400.ms, curve: Curves.easeOutQuad)
               .fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
