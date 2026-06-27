import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/animated_blob_background.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for leaderboard
    final topDonors = [
      {'name': 'Karan Rathod', 'coins': 4500, 'co2': 120, 'rank': 1},
      {'name': 'Anita Desai', 'coins': 3800, 'co2': 95, 'rank': 2},
      {'name': 'Rahul Sharma', 'coins': 3200, 'co2': 80, 'rank': 3},
      {'name': 'Priya Singh', 'coins': 2900, 'co2': 75, 'rank': 4},
      {'name': 'Sanjay Gupta', 'coins': 2100, 'co2': 50, 'rank': 5},
    ];

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBlobBackground(child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Text('Nashik Top Donors', style: AppTextStyles.headline),
                    ],
                  ),
                ).animate().slideX(begin: -0.2).fadeIn(),
                
                // Leaderboard List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: topDonors.length,
                    itemBuilder: (context, index) {
                      final donor = topDonors[index];
                      final isTop3 = (donor['rank'] as int) <= 3;
                      
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            // Rank Badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isTop3 ? AppColors.tertiary : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '#${donor['rank']}',
                                  style: AppTextStyles.title.copyWith(
                                    color: isTop3 ? Colors.white : AppColors.textPrimary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(donor['name'] as String, style: AppTextStyles.title.copyWith(fontSize: 18)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saved ${donor['co2']} kg CO2',
                                    style: AppTextStyles.body.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Coins
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.eco_rounded, color: Colors.green, size: 20),
                                    const SizedBox(width: 4),
                                    Text('${donor['coins']}', style: AppTextStyles.title.copyWith(color: Colors.green, fontSize: 18)),
                                  ],
                                ),
                                Text('Eco-Coins', style: AppTextStyles.body.copyWith(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: 0.2).fadeIn(delay: Duration(milliseconds: 200 + (index * 100)));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
