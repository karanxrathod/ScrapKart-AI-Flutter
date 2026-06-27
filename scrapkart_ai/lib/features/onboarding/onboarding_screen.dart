import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/animated_blob_background.dart';
import '../../core/widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Sell Your Scrap Easily',
      'subtitle': 'Turn waste into money with smart AI pricing',
      'icon': Icons.recycling,
      'color': AppColors.secondary,
    },
    {
      'title': 'AI Smart Detection',
      'subtitle': 'Upload image and detect scrap instantly',
      'icon': Icons.document_scanner,
      'color': AppColors.primary,
    },
    {
      'title': 'Fast Pickup',
      'subtitle': 'Nearby collectors will pick your scrap',
      'icon': Icons.local_shipping,
      'color': AppColors.tertiary,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBlobBackground(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Center(
                      child: GlassCard(
                        padding: const EdgeInsets.all(32),
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _pages[index]['color'].withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                _pages[index]['icon'],
                                size: 100,
                                color: _pages[index]['color'],
                              ),
                            ).animate(key: ValueKey(_currentPage))
                             .scale(duration: 500.ms, curve: Curves.easeOutBack)
                             .fadeIn(),
                            const SizedBox(height: 48),
                            Text(
                              _pages[index]['title'],
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headline.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ).animate(key: ValueKey('title_$_currentPage'))
                             .slideY(begin: 0.5, end: 0, duration: 400.ms)
                             .fadeIn(),
                            const SizedBox(height: 16),
                            Text(
                              _pages[index]['subtitle'],
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ).animate(key: ValueKey('sub_$_currentPage'))
                             .slideY(begin: 0.5, end: 0, duration: 400.ms, delay: 100.ms)
                             .fadeIn(delay: 100.ms),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Pagination & Buttons
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _currentPage == index ? 24 : 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next / Get Started
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ).animate(key: ValueKey(_currentPage))
                   .fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
