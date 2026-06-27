import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/animated_blob_background.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/local_db_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const BookingScreen({super.key, this.initialData});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final List<String> _selectedTypes = [];
  final List<String> _scrapTypes = ['Paper / Cardboard', 'Plastics', 'E-Waste', 'Glass', 'Metals'];

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, String>> _savedAddresses = [];
  List<Map<String, String>> _savedPaymentMethods = [];
  String _selectedAddressLabel = 'Custom';
  String _selectedPayoutMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    
    // Set default date & time for pickup (e.g. today, 2 hours from now)
    final now = DateTime.now();
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _timeController.text = '${(now.hour + 2) % 24}:00';

    _addressController.addListener(_onAddressChanged);
    _loadSavedData();

    if (widget.initialData != null) {
      final initial = widget.initialData!;
      // Pre-fill weight
      if (initial['weight'] != null) {
        _weightController.text = initial['weight'].toString();
      }

      // Pre-fill scrap types if matched
      final category = initial['suggestedCategory']?.toString();
      if (category != null) {
        if (category.toLowerCase().contains('plastic') && !_selectedTypes.contains('Plastics')) {
          _selectedTypes.add('Plastics');
        } else if (category.toLowerCase().contains('metal') && !_selectedTypes.contains('Metals')) {
          _selectedTypes.add('Metals');
        } else if (category.toLowerCase().contains('paper') || category.toLowerCase().contains('cardboard')) {
          if (!_selectedTypes.contains('Paper / Cardboard')) {
            _selectedTypes.add('Paper / Cardboard');
          }
        } else if (category.toLowerCase().contains('glass') && !_selectedTypes.contains('Glass')) {
          _selectedTypes.add('Glass');
        } else if (category.toLowerCase().contains('waste') || category.toLowerCase().contains('keyboard') || category.toLowerCase().contains('e-waste')) {
          if (!_selectedTypes.contains('E-Waste')) {
            _selectedTypes.add('E-Waste');
          }
        }
      }
    }
  }

  Future<void> _loadSavedData() async {
    final addresses = await LocalDbService.instance.getSavedAddresses();
    final payments = await LocalDbService.instance.getSavedPaymentMethods();
    if (mounted) {
      setState(() {
        _savedAddresses = addresses;
        _savedPaymentMethods = payments;
      });
    }
  }

  void _onAddressChanged() {
    if (_selectedAddressLabel != 'Custom') {
      final match = _savedAddresses.firstWhere(
        (a) => a['label'] == _selectedAddressLabel,
        orElse: () => {},
      );
      if (match.isEmpty || match['addressLine'] != _addressController.text) {
        setState(() {
          _selectedAddressLabel = 'Custom';
        });
      }
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedTypes.isEmpty || _weightController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill scrap type, weight, and address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double weight = double.tryParse(_weightController.text) ?? 0.0;
      double? estimatedPrice;
      if (widget.initialData != null && widget.initialData!['estimatedPrice'] != null) {
        estimatedPrice = (widget.initialData!['estimatedPrice'] as num).toDouble();
        // If the weight was changed, scale the price accordingly
        final double initialWeight = (widget.initialData!['weight'] as num?)?.toDouble() ?? weight;
        if (initialWeight > 0 && initialWeight != weight) {
          final double pricePerKg = (widget.initialData!['estimatedPricePerKg'] as num?)?.toDouble() ?? 15.0;
          estimatedPrice = weight * pricePerKg;
        }
      } else {
        // Calculate based on selected types
        double maxRate = 15.0;
        for (final t in _selectedTypes) {
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
        estimatedPrice = weight * maxRate;
      }

      // Save data locally using LocalDbService
      await LocalDbService.instance.addBooking(
        scrapTypes: _selectedTypes,
        estimatedWeight: _weightController.text,
        pickupAddress: _addressController.text,
        date: _dateController.text,
        time: _timeController.text,
        estimatedPrice: estimatedPrice,
        payoutMethod: _selectedPayoutMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scrap Pickup Booked Locally! 🎉')),
        );
        context.push('/tracking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _weightController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Widget _buildAddressChips() {
    final List<String> labels = _savedAddresses.map((a) => a['label'] ?? '').toList();
    if (!labels.contains('Custom')) {
      labels.add('Custom');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.map((label) {
          final isSelected = _selectedAddressLabel == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label, style: AppTextStyles.body.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
              )),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isSelected ? AppColors.primary : Colors.white)
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedAddressLabel = label;
                    if (label != 'Custom') {
                      final match = _savedAddresses.firstWhere((a) => a['label'] == label);
                      _addressController.text = match['addressLine'] ?? '';
                    } else {
                      _addressController.clear();
                    }
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPayoutDetailsWidget() {
    final match = _savedPaymentMethods.firstWhere(
      (p) => p['type']?.toLowerCase() == _selectedPayoutMethod.toLowerCase(),
      orElse: () => {},
    );

    if (match.isNotEmpty && match['details'] != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Linked details: ${match['details']}',
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    } else if (_selectedPayoutMethod != 'Cash') {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No saved details for $_selectedPayoutMethod found. Add them in Profile.',
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Pickup', style: AppTextStyles.title),
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
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scrap Details', style: AppTextStyles.headline.copyWith(fontSize: 24))
                    .animate().slideX(begin: -0.2).fadeIn(),
                const SizedBox(height: 24),
                
                // Scrap Types (Multiple Selection)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _scrapTypes.map((type) {
                    final isSelected = _selectedTypes.contains(type);
                    return FilterChip(
                      label: Text(type, style: AppTextStyles.body.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      )),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? AppColors.primary : Colors.white)
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        });
                      },
                    );
                  }).toList(),
                ).animate().slideY(begin: 0.2).fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                
                // Weight
                _buildTextField(
                  controller: _weightController,
                  hint: 'Estimated Weight (kg)',
                  icon: Icons.monitor_weight_rounded,
                  keyboardType: TextInputType.number,
                ).animate().slideY(begin: 0.2).fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                
                // Pickup Address
                Text('Pickup Address', style: AppTextStyles.headline.copyWith(fontSize: 16))
                    .animate().slideX(begin: -0.2).fadeIn(delay: 250.ms),
                const SizedBox(height: 8),
                _buildAddressChips().animate().slideY(begin: 0.2).fadeIn(delay: 280.ms),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _addressController,
                  hint: 'Pickup Address',
                  icon: Icons.location_on_rounded,
                  maxLines: 2,
                ).animate().slideY(begin: 0.2).fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                
                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _dateController,
                        hint: 'Date',
                        icon: Icons.calendar_today_rounded,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _timeController,
                        hint: 'Time',
                        icon: Icons.access_time_rounded,
                      ),
                    ),
                  ],
                ).animate().slideY(begin: 0.2).fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                
                // Payout Method Selector
                Text('Payout Method', style: AppTextStyles.headline.copyWith(fontSize: 16))
                    .animate().slideX(begin: -0.2).fadeIn(delay: 420.ms),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['UPI', 'Card', 'Cash'].map((method) {
                    final isSelected = _selectedPayoutMethod == method;
                    IconData icon;
                    switch (method) {
                      case 'UPI':
                        icon = Icons.account_balance_wallet_outlined;
                        break;
                      case 'Card':
                        icon = Icons.credit_card_outlined;
                        break;
                      default:
                        icon = Icons.money_outlined;
                    }
                    return ChoiceChip(
                      avatar: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 18),
                      label: Text(method, style: AppTextStyles.body.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      )),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isSelected ? AppColors.primary : Colors.white)
                      ),
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedPayoutMethod = method;
                          });
                        }
                      },
                    );
                  }).toList(),
                ).animate().slideY(begin: 0.2).fadeIn(delay: 450.ms),
                const SizedBox(height: 8),
                _buildPayoutDetailsWidget().animate().fadeIn(delay: 480.ms),
                
                const SizedBox(height: 40),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Schedule Pickup', style: AppTextStyles.button),
                  ),
                ).animate().scale(delay: 500.ms).fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint, 
    required IconData icon, 
    TextEditingController? controller,
    TextInputType? keyboardType, 
    int maxLines = 1
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
