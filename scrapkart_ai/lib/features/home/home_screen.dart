import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/local_db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onScanTap;
  
  const HomeScreen({super.key, this.onProfileTap, this.onScanTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = 'Karan';
  List<Map<String, dynamic>> _bookings = [];
  double _totalEarnings = 0.0;
  double _totalWeight = 0.0;
  bool _isLoadingBookings = true;
  
  // Gamification Metrics
  double _treesSaved = 0.0;
  double _co2SavedKg = 0.0;
  int _points = 0;
  String _badge = 'Eco Starter';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookings();
  }

  Future<void> _loadUserProfile() async {
    final localUser = await LocalDbService.instance.getCurrentUser();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // Fetch from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _displayName = doc.data()?['name'] ?? localUser?['name'] ?? 'Karan';
          _treesSaved = (doc.data()?['treesSaved'] ?? 0.0).toDouble();
          _co2SavedKg = (doc.data()?['co2SavedKg'] ?? 0.0).toDouble();
          _points = doc.data()?['points'] ?? 0;
          
          List<dynamic> badges = doc.data()?['badges'] ?? [];
          if (badges.isNotEmpty) {
            _badge = badges.last.toString();
          }
        });
      }
    } else if (localUser != null && mounted) {
      setState(() {
        _displayName = localUser['name'] ?? 'Karan';
      });
    }
  }

  Future<void> _loadBookings() async {
    try {
      final list = await LocalDbService.instance.getBookings();
      double earnings = 0.0;
      double weight = 0.0;
      for (final b in list) {
        final double w = double.tryParse(b['actualWeight']?.toString() ?? b['estimatedWeight']?.toString() ?? '') ?? 0.0;
        weight += w;
        
        double price = double.tryParse(b['actualPrice']?.toString() ?? b['estimatedPrice']?.toString() ?? '') ?? 0.0;
        if (price == 0.0) {
          double maxRate = 15.0;
          final scrapTypes = List<String>.from(b['scrapTypes'] ?? []);
          for (final t in scrapTypes) {
            double rate = 15.0;
            if (t.toLowerCase().contains('metal')) {
              rate = 75.0;
            } else if (t.toLowerCase().contains('e-waste')) {
              rate = 50.0;
            } else if (t.toLowerCase().contains('plastic')) {
              rate = 15.0;
            } else if (t.toLowerCase().contains('paper') || t.toLowerCase().contains('cardboard')) {
              rate = 12.0;
            } else if (t.toLowerCase().contains('glass')) {
              rate = 8.0;
            }
            if (rate > maxRate) {
              maxRate = rate;
            }
          }
          price = w * maxRate;
        }
        earnings += price;
      }
      if (mounted) {
        setState(() {
          _bookings = list;
          _totalEarnings = earnings;
          _totalWeight = weight;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings in HomeScreen: $e');
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Greeting Map
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Image.asset('assets/images/logo.png', width: 40, height: 40),
                   const SizedBox(width: 12),
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hi, $_displayName 👋', style: AppTextStyles.headline.copyWith(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text('ScrapKart AI', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ).animate().slideX(begin: -0.2).fadeIn(),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.tertiary.withValues(alpha: 0.5),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ).animate().scale().fadeIn(),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Stats Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earnings', style: AppTextStyles.body),
                    const SizedBox(height: 8),
                    Text('₹ ${_totalEarnings.toStringAsFixed(0)}', style: AppTextStyles.headline.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 16),
                    Text('Scrap Sold', style: AppTextStyles.body),
                    const SizedBox(height: 4),
                    Text('${_totalWeight.toStringAsFixed(1)} kg', style: AppTextStyles.title.copyWith(fontSize: 18)),
                  ],
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _totalWeight > 0 ? (_totalWeight / 50.0).clamp(0.0, 1.0) : 0.0,
                        strokeWidth: 10,
                        backgroundColor: Colors.white,
                        color: AppColors.tertiary,
                      ),
                      const Icon(Icons.eco, color: AppColors.primary, size: 30),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2).fadeIn(),
          
          const SizedBox(height: 24),
          
          // Eco-Impact Gamification Widget
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Eco Impact', style: AppTextStyles.title),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.accent, size: 16),
                          const SizedBox(width: 4),
                          Text('$_points pts - $_badge', style: AppTextStyles.body.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildEcoStat(
                        icon: Icons.park,
                        value: _treesSaved.toStringAsFixed(1),
                        label: 'Trees Saved',
                        color: Colors.greenAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildEcoStat(
                        icon: Icons.cloud,
                        value: '$_co2SavedKg',
                        label: 'CO₂ Reduced (kg)',
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2).fadeIn(delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Quick Actions
          Text('Quick Actions', style: AppTextStyles.title)
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildActionCard(
                  context,
                  title: 'Sell Scrap',
                  icon: Icons.sell_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.push('/booking'),
                  delay: 300,
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  context,
                  title: 'AI Scan',
                  icon: Icons.document_scanner_rounded,
                  color: AppColors.primary,
                  onTap: widget.onScanTap ?? () => context.go('/scan'),
                  delay: 400,
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  context,
                  title: 'Donate',
                  icon: Icons.volunteer_activism_rounded,
                  color: AppColors.tertiary,
                  onTap: () => context.push('/donate'),
                  delay: 500,
                ),
                const SizedBox(width: 16),
                _buildActionCard(
                  context,
                  title: 'Wallet',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.blueAccent,
                  onTap: () => context.push('/wallet'),
                  delay: 600,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // AI Recommendations
          Text('AI Recommendations', style: AppTextStyles.title)
              .animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRecommendationItem('Plastic bottle', 'Recycle', Icons.recycling),
                const Divider(color: Colors.white),
                _buildRecommendationItem('Old clothes', 'Donate', Icons.checkroom),
              ],
            ),
          ).animate().slideY(begin: 0.2).fadeIn(delay: 700.ms),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          Text('Recent Activity', style: AppTextStyles.title)
              .animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 16),
          if (_isLoadingBookings)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_bookings.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'No bookings yet',
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your scheduled scrap pickups will appear here.',
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.2).fadeIn(delay: 900.ms)
          else ...[
            ..._bookings.take(2).map((booking) {
              final status = booking['status']?.toString() ?? 'Pending';
              final weight = booking['estimatedWeight']?.toString() ?? '0';
              final scrapTypes = List<String>.from(booking['scrapTypes'] ?? []);
              final title = '${scrapTypes.isNotEmpty ? scrapTypes.join(", ") : "Scrap"} (${weight}kg)';
              final date = booking['date']?.toString() ?? 'Today';
              final time = booking['time']?.toString() ?? '';
              final dateTimeStr = time.isNotEmpty ? '$date, $time' : date;
              
              Color statusColor = AppColors.primary;
              if (status.toLowerCase() == 'completed') {
                statusColor = AppColors.tertiary;
              } else if (status.toLowerCase() == 'pending') {
                statusColor = AppColors.accent;
              } else if (status.toLowerCase() == 'cancelled') {
                statusColor = Colors.redAccent;
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildRecentActivityItem(title, status, dateTimeStr, statusColor),
              );
            }),
          ],
              
          const SizedBox(height: 120.0), // padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap, required int delay}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().scale(delay: delay.ms).fadeIn(delay: delay.ms);
  }

  Widget _buildEcoStat({required IconData icon, required String value, required String label, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headline.copyWith(fontSize: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.body.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String item, String action, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(item, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              action,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(String title, String status, String date, Color statusColor) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restore_outlined, color: statusColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(
            status,
            style: AppTextStyles.body.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
