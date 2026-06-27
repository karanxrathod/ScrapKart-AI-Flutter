import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/animated_blob_background.dart';

class PredictionScreen extends StatefulWidget {
  final Map<String, dynamic>? scanResult;
  const PredictionScreen({super.key, this.scanResult});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  double _weight = 1.0;
  int _pricePerKg = 15;
  String _material = 'Plastic Bottle (PET)';
  String _category = 'Recyclable Plastics';
  int? _volumeLiters;

  @override
  void initState() {
    super.initState();
    if (widget.scanResult != null) {
      _weight = (widget.scanResult!['estimatedWeightKg'] as num?)?.toDouble() ?? (widget.scanResult!['weight'] as num?)?.toDouble() ?? 1.0;
      _pricePerKg = (widget.scanResult!['estimatedPricePerKg'] as num?)?.toInt() ?? 15;
      _material = widget.scanResult!['material']?.toString() ?? 'Plastic Bottle (PET)';
      _category = widget.scanResult!['suggestedCategory']?.toString() ?? 'Recyclable Plastics';
      _volumeLiters = (widget.scanResult!['estimatedVolumeLiters'] as num?)?.toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double estimatedPrice = _weight * _pricePerKg;

    return Scaffold(
      appBar: AppBar(
        title: Text('Price Prediction', style: AppTextStyles.title),
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
            children: [
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.recycling, size: 40, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 16),
                    Text(_material, style: AppTextStyles.headline.copyWith(fontSize: 22), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Base Value: ₹$_pricePerKg / kg', style: AppTextStyles.body),
                    if (_volumeLiters != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'AI Est. Volume: $_volumeLiters Liters',
                          style: AppTextStyles.body.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(begin: 0.2).fadeIn(),
              
              const SizedBox(height: 24),
              
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Adjust Estimated Weight', style: AppTextStyles.title),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 36),
                          onPressed: () {
                            if (_weight > 0.1) {
                              setState(() {
                                _weight = double.parse((_weight - 0.1).toStringAsFixed(1));
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '$_weight kg',
                            style: AppTextStyles.title.copyWith(fontSize: 20, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 36),
                          onPressed: () {
                            setState(() {
                              _weight = double.parse((_weight + 0.1).toStringAsFixed(1));
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Total Estimated Value', style: AppTextStyles.subtitle),
                    const SizedBox(height: 8),
                    Text(
                      '₹${estimatedPrice.toStringAsFixed(0)}', 
                      style: AppTextStyles.headline.copyWith(fontSize: 54, color: AppColors.primary),
                    ),
                    const SizedBox(height: 24),
                    // Mock Graph Layout
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Market Trend Chart \n(Prices are stable for $_category)', 
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI suggests booking a pickup now. Prices in Nashik are favorable today.',
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2).fadeIn(delay: 200.ms),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Semantics(
                  button: true,
                  label: 'Go to Schedule Pickup Button',
                  child: ElevatedButton(
                    onPressed: () {
                      final updatedResult = {
                        'material': _material,
                        'conditionFactor': widget.scanResult?['conditionFactor'] ?? 0.8,
                        'estimatedPricePerKg': _pricePerKg,
                        'suggestedCategory': _category,
                        'weight': _weight,
                        'estimatedPrice': estimatedPrice,
                      };
                      context.push('/booking', extra: updatedResult);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('Schedule Pickup', style: AppTextStyles.button),
                  ),
                ),
              ).animate().scale(delay: 400.ms).fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
