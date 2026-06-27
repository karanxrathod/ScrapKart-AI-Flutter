import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/local_db_service.dart';

class BookingsListScreen extends StatefulWidget {
  final VoidCallback? onNewBookingTap;
  const BookingsListScreen({super.key, this.onNewBookingTap});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final list = await LocalDbService.instance.getBookings();
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading local bookings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Pickups',
                  style: AppTextStyles.headline,
                ).animate().slideY(begin: -0.2).fadeIn(),
                const SizedBox(height: 4),
                Text(
                  'Track your scheduled scrap collections (stored locally)',
                  style: AppTextStyles.subtitle,
                ).animate().slideY(begin: -0.2).fadeIn(delay: 100.ms),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    color: AppColors.primary,
                    child: _bookings.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final data = _bookings[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: _buildBookingCard(context, data, data['id'] ?? index.toString()),
                              ).animate().slideY(begin: 0.2).fadeIn(delay: (index * 50).ms);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> data, String id) {
    final status = data['status']?.toString() ?? 'Pending';
    final weight = data['estimatedWeight']?.toString() ?? 'Unknown';
    final date = data['date']?.toString() ?? 'Today';
    final time = data['time']?.toString() ?? 'Flexible';
    final address = data['pickupAddress']?.toString() ?? 'No address provided';
    final types = List<String>.from(data['scrapTypes'] ?? []);

    Color statusColor = Colors.orange;
    if (status.toLowerCase() == 'completed') {
      statusColor = Colors.green;
    } else if (status.toLowerCase() == 'cancelled') {
      statusColor = Colors.redAccent;
    } else if (status.toLowerCase() == 'assigned' || status.toLowerCase() == 'in progress') {
      statusColor = AppColors.primary;
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$date • $time',
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chips for Scrap Types
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: types.map((type) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  type,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textPrimary),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated Weight', style: AppTextStyles.body.copyWith(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('$weight kg', style: AppTextStyles.title.copyWith(fontSize: 15)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/tracking?id=$id');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ).animate().scale(duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'No Scheduled Pickups',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule a collection, and our verified collectors will pick it up from Nashik city.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.onNewBookingTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Schedule Now', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}
