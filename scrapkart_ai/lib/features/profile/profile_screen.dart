import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/widgets/glass_card.dart';
import '../../services/gemini_service.dart';
import '../../services/local_db_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOrderHistoryTap;
  const ProfileScreen({super.key, this.onOrderHistoryTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isApiKeySet = false;
  String _currentKey = '';
  String _name = 'Karan';
  String _email = 'karan@example.com';
  double _totalSoldWeight = 0.0;
  double _totalEarnings = 0.0;
  int _totalPickupsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _loadUserProfile();
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookings();
  }

  Future<void> _loadUserProfile() async {
    final user = await LocalDbService.instance.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _name = user['name'] ?? 'Karan';
        _email = user['email'] ?? 'karan@example.com';
      });
    }
  }

  Future<void> _loadBookings() async {
    try {
      final list = await LocalDbService.instance.getBookings();
      double weight = 0.0;
      double earnings = 0.0;
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
          _totalSoldWeight = weight;
          _totalEarnings = earnings;
          _totalPickupsCount = list.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings in ProfileScreen: $e');
    }
  }

  Future<void> _checkApiKey() async {
    final hasKey = await GeminiService.instance.hasApiKey();
    final key = await GeminiService.instance.getApiKey();
    if (mounted) {
      setState(() {
        _isApiKeySet = hasKey;
        _currentKey = key ?? '';
      });
    }
  }

  void _showApiKeyBottomSheet(BuildContext context) {
    final controller = TextEditingController(text: _currentKey);
    bool obscureText = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Gemini API Key', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Text(
                    'Directly call Gemini 2.5 Flash on your device. Paste your API key below. Get a free API Key from Google AI Studio.',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 12),
                  const SelectableText(
                    'https://aistudio.google.com/',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: controller,
                      obscureText: obscureText,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter API Key (AIzaSy...)',
                        hintStyle: AppTextStyles.body,
                        prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setSheetState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_isApiKeySet) ...[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                              foregroundColor: Colors.redAccent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              await GeminiService.instance.clearApiKey();
                              await _checkApiKey();
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('API Key cleared successfully.')),
                                );
                              }
                            },
                            child: const Text('Delete Key'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            final newKey = controller.text.trim();
                            if (newKey.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Key cannot be empty.')),
                              );
                              return;
                            }
                            await GeminiService.instance.saveApiKey(newKey);
                            await _checkApiKey();
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gemini API Key saved successfully! 🎉')),
                              );
                            }
                          },
                          child: Text('Save Key', style: AppTextStyles.button),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSavedAddressesBottomSheet(BuildContext context) {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    List<Map<String, String>> addresses = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> reload() async {
              final list = await LocalDbService.instance.getSavedAddresses();
              setSheetState(() {
                addresses = list;
              });
            }

            if (addresses.isEmpty) {
              reload();
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Saved Addresses', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  if (addresses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No saved addresses yet.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          return Card(
                            color: Colors.white.withValues(alpha: 0.5),
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            child: ListTile(
                              title: Text(addr['label'] ?? '', style: AppTextStyles.title.copyWith(fontSize: 14)),
                              subtitle: Text(addr['addressLine'] ?? '', style: AppTextStyles.body.copyWith(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  await LocalDbService.instance.deleteSavedAddress(addr['id']!);
                                  reload();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Add New Address', style: AppTextStyles.title.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: labelController,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Address Label (e.g. Home, Office)',
                        hintStyle: AppTextStyles.body,
                        prefixIcon: const Icon(Icons.label_outline, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: addressController,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Address Line',
                        hintStyle: AppTextStyles.body,
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final label = labelController.text.trim();
                        final addressLine = addressController.text.trim();
                        if (label.isEmpty || addressLine.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter both label and address line.')),
                          );
                          return;
                        }
                        await LocalDbService.instance.addSavedAddress(label, addressLine);
                        labelController.clear();
                        addressController.clear();
                        reload();
                      },
                      child: Text('Add Address', style: AppTextStyles.button.copyWith(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentMethodsBottomSheet(BuildContext context) {
    final detailsController = TextEditingController();
    String selectedType = 'UPI';
    List<Map<String, String>> payments = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> reload() async {
              final list = await LocalDbService.instance.getSavedPaymentMethods();
              setSheetState(() {
                payments = list;
              });
            }

            if (payments.isEmpty) {
              reload();
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Payment Methods', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  if (payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No saved payment methods yet.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final pay = payments[index];
                          return Card(
                            color: Colors.white.withValues(alpha: 0.5),
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.white, width: 1.5),
                            ),
                            child: ListTile(
                              leading: Icon(
                                pay['type'] == 'UPI'
                                    ? Icons.account_balance_wallet_outlined
                                    : pay['type'] == 'Card'
                                        ? Icons.credit_card_outlined
                                        : Icons.money_outlined,
                                color: AppColors.primary,
                              ),
                              title: Text(pay['type'] ?? '', style: AppTextStyles.title.copyWith(fontSize: 14)),
                              subtitle: Text(pay['details'] ?? '', style: AppTextStyles.body.copyWith(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () async {
                                  await LocalDbService.instance.deleteSavedPaymentMethod(pay['id']!);
                                  reload();
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Add New Method', style: AppTextStyles.title.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['UPI', 'Card', 'Cash'].map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
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
                          if (selected) {
                            setSheetState(() {
                              selectedType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: detailsController,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: selectedType == 'Cash'
                            ? 'Details (e.g. Hand over cash)'
                            : selectedType == 'UPI'
                                ? 'UPI ID (e.g. user@okhdfcbank)'
                                : 'Card Number details (e.g. **** **** **** 1234)',
                        hintStyle: AppTextStyles.body,
                        prefixIcon: Icon(
                          selectedType == 'UPI'
                              ? Icons.account_balance_wallet_outlined
                              : selectedType == 'Card'
                                  ? Icons.credit_card_outlined
                                  : Icons.money_outlined,
                          color: AppColors.primary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final details = detailsController.text.trim();
                        if (details.isEmpty && selectedType != 'Cash') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter details.')),
                          );
                          return;
                        }
                        final detailsText = selectedType == 'Cash' && details.isEmpty ? 'Cash on Delivery' : details;
                        await LocalDbService.instance.addSavedPaymentMethod(selectedType, detailsText);
                        detailsController.clear();
                        reload();
                      },
                      child: Text('Add Payment Method', style: AppTextStyles.button.copyWith(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Profile Info
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
                  child: const Icon(Icons.person, size: 50, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(_name, style: AppTextStyles.headline),
                Text(_email, style: AppTextStyles.body),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('${_totalSoldWeight.toStringAsFixed(1)}kg', 'Total Sold'),
                    Container(width: 1, height: 40, color: Colors.white),
                    _buildStatCol('₹ ${_totalEarnings.toStringAsFixed(0)}', 'Earnings'),
                    Container(width: 1, height: 40, color: Colors.white),
                    _buildStatCol('$_totalPickupsCount', 'Pickups'),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: -0.2).fadeIn(),
          
          const SizedBox(height: 32),
          
          // Options List
          _buildOptionTile(
            Icons.restore_rounded, 
            'Order History', 
            AppColors.tertiary,
            onTap: widget.onOrderHistoryTap,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          _buildOptionTile(
            Icons.payment_rounded, 
            'Payment Methods', 
            AppColors.accent,
            onTap: () => _showPaymentMethodsBottomSheet(context),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          _buildOptionTile(
            Icons.location_on_rounded, 
            'Saved Addresses', 
            AppColors.secondary,
            onTap: () => _showSavedAddressesBottomSheet(context),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
          _buildOptionTile(
            Icons.vpn_key_rounded, 
            'Gemini API Settings', 
            AppColors.primary,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isApiKeySet ? 'Connected' : 'Configure',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isApiKeySet ? Colors.green : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isApiKeySet ? Icons.check_circle : Icons.warning_rounded,
                  color: _isApiKeySet ? Colors.green : Colors.orangeAccent,
                  size: 20,
                ),
              ],
            ),
            onTap: () => _showApiKeyBottomSheet(context),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 16),
          _buildOptionTile(
            Icons.logout_rounded, 
            'Logout', 
            Colors.redAccent,
            onTap: () async {
              await LocalDbService.instance.logoutUserLocal();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ).animate().fadeIn(delay: 600.ms),
          
          const SizedBox(height: 120.0), // App bar padding
        ],
      ),
    );
  }

  Widget _buildStatCol(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.title.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.body.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color color, {VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16))),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
