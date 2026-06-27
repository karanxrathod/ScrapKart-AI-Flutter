import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/animated_blob_background.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final double _balance = 1250.0;
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Scrap Sold (Metal)',
      'date': 'Oct 24, 2023',
      'amount': 450.0,
      'isCredit': true,
    },
    {
      'title': 'Withdrawal to Bank',
      'date': 'Oct 20, 2023',
      'amount': 1000.0,
      'isCredit': false,
    },
    {
      'title': 'Scrap Sold (Paper)',
      'date': 'Oct 15, 2023',
      'amount': 120.0,
      'isCredit': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallet', style: AppTextStyles.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBlobBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 60,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text('Total Balance', style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_balance.toStringAsFixed(2)}',
                      style: AppTextStyles.headline.copyWith(fontSize: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Withdrawal initiated!')),
                              );
                            },
                            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                            label: Text('Withdraw', style: AppTextStyles.button),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2).fadeIn(),
              
              const SizedBox(height: 32),
              
              Text('Recent Transactions', style: AppTextStyles.title)
                  .animate().fadeIn(delay: 200.ms),
                  
              const SizedBox(height: 16),
              
              ..._transactions.map((tx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tx['isCredit'] ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tx['isCredit'] ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx['isCredit'] ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx['title'], style: AppTextStyles.title.copyWith(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(tx['date'], style: AppTextStyles.body.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '${tx['isCredit'] ? '+' : '-'}₹${tx['amount'].toStringAsFixed(0)}',
                          style: AppTextStyles.title.copyWith(
                            color: tx['isCredit'] ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.1).fadeIn(delay: 300.ms),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
