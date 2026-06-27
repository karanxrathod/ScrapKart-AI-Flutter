import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/animated_blob_background.dart';
import 'donate_controller.dart';

class DonateScreen extends ConsumerStatefulWidget {
  const DonateScreen({super.key});

  @override
  ConsumerState<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends ConsumerState<DonateScreen> {
  String? _selectedCategory;
  String? _selectedNgo;
  final _categories = ['Old Clothes', 'Books & Stationery', 'E-Waste', 'Furniture', 'Toys'];
  
  @override
  Widget build(BuildContext context) {
    final donateState = ref.watch(donateControllerProvider);

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 8),
                          Text('Donate', style: AppTextStyles.headline),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 30),
                        onPressed: () => context.push('/leaderboard'),
                      ),
                    ],
                  ).animate().slideX(begin: -0.2).fadeIn(),
                  
                  const SizedBox(height: 32),

                  // Gamified Impact Banner
                  donateState.when(
                    data: (data) {
                      final stats = data['stats'] ?? {};
                      return GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.eco_rounded, color: Colors.green, size: 40),
                                const SizedBox(height: 8),
                                Text('${stats['totalCoins'] ?? 0}', style: AppTextStyles.title.copyWith(color: Colors.green)),
                                Text('Eco-Coins', style: AppTextStyles.body.copyWith(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Your Global Impact', style: AppTextStyles.title),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You have saved ${stats['totalCO2'] ?? 0} kg of CO2 from the atmosphere!',
                                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: 0.2).fadeIn(delay: 200.ms);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Failed to load stats: $err', style: TextStyle(color: Colors.red)),
                  ),

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

                  // NGO Transparency Hub (Progress Bars)
                  donateState.when(
                    data: (data) {
                      final ngos = data['ngos'] as List<dynamic>? ?? [];
                      if (ngos.isEmpty) return const SizedBox();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NGO Transparency Hub', style: AppTextStyles.title).animate().fadeIn(delay: 500.ms),
                          const SizedBox(height: 8),
                          Text('See where your donations make a real impact.', style: AppTextStyles.body),
                          const SizedBox(height: 16),
                          ...ngos.map((ngo) {
                            final double progress = ngo['raised'] / ngo['goal'];
                            return GlassCard(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(ngo['name'], style: AppTextStyles.title.copyWith(fontSize: 16)),
                                      Text('${(progress * 100).toStringAsFixed(0)}%', style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Goal: ${ngo['impact']} (₹${ngo['goal']})', style: AppTextStyles.body.copyWith(fontSize: 12)),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.white24,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().slideX(begin: 0.2).fadeIn(delay: 600.ms);
                          }),
                          const SizedBox(height: 24),
                          // Dropdown to select NGO
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: Text('Select an NGO to support', style: AppTextStyles.body.copyWith(color: Colors.black54)),
                                value: _selectedNgo,
                                items: ngos.map((ngo) {
                                  return DropdownMenuItem<String>(
                                    value: ngo['name'],
                                    child: Text(ngo['name'], style: AppTextStyles.body.copyWith(color: Colors.black87)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNgo = value;
                                  });
                                },
                              ),
                            ),
                          ).animate().fadeIn(delay: 700.ms),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (e, st) => const SizedBox(),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _selectedCategory == null || _selectedNgo == null ? null : () async {
                        try {
                           // Example: 5kg fixed weight for demo
                          await ref.read(donateControllerProvider.notifier).submitDonation(
                            scrapType: _selectedCategory!,
                            weightKg: 5.0,
                            ngoName: _selectedNgo,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Donation successful! +50 EcoCoins!', style: AppTextStyles.body.copyWith(color: Colors.white)),
                                backgroundColor: AppColors.tertiary,
                              ),
                            );
                          }
                        } catch (e) {
                           if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                           }
                        }
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
                      child: donateState.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Confirm Donation',
                              style: AppTextStyles.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().scale(delay: 800.ms).fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
