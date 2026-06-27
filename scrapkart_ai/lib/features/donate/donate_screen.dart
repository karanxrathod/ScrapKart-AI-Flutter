import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/animated_blob_background.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  String? _selectedCategory;
  final _categories = ['Old Clothes', 'Books & Stationery', 'E-Waste', 'Furniture', 'Toys'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBlobBackground(child: SizedBox.expand()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar / Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text('Donate Dashboard', style: AppTextStyles.headline),
                    ],
                  ).animate().slideX(begin: -0.2).fadeIn(),
                  
                  const SizedBox(height: 32),
                  
                  // Summary Banner
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.tertiary, size: 40),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Make an Impact', style: AppTextStyles.title),
                              const SizedBox(height: 8),
                              Text(
                                'Give your pre-loved goods a second life with verified NGOs.',
                                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2).fadeIn(delay: 200.ms),

                  const SizedBox(height: 40),
                  
                  Text('What would you like to donate?', style: AppTextStyles.title).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  
                  // Wrap Categories
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.tertiary : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.tertiary : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            category,
                            style: AppTextStyles.body.copyWith(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),
                  
                  // Condition Details
                  Text('Item Details (Optional)', style: AppTextStyles.title).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(4),
                    child: TextFormField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'E.g., 5 pairs of shirts in good condition',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ).animate().slideY(begin: 0.2).fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 40),
                  
                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Demo submit action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Thank you! An NGO representative will contact you soon.',
                              style: AppTextStyles.body.copyWith(color: Colors.white),
                            ),
                            backgroundColor: AppColors.tertiary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (context.mounted) context.pop();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tertiary,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: AppColors.tertiary.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        'Confirm Donation',
                        style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ).animate().scale(delay: 700.ms).fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
