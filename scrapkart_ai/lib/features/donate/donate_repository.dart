import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Offline Donate Repository ───────────────────────────────────────────────
// No network calls. All data is local (SharedPreferences + hardcoded).
// ─────────────────────────────────────────────────────────────────────────────

final donateRepositoryProvider = Provider<DonateRepository>((ref) {
  return DonateRepository();
});

class DonateRepository {
  static const String _statsKey = 'donate_stats';
  static const String _donationsKey = 'donations_list';

  // Static NGO data - fully offline
  static final List<Map<String, dynamic>> _partnerNgos = [
    {
      'name': 'Green Earth NGO',
      'goal': 50000,
      'raised': 35000,
      'impact': 'Ocean Cleanup',
      'description': 'Cleaning Nashik rivers and water bodies',
    },
    {
      'name': 'Child Education Trust',
      'goal': 25000,
      'raised': 10000,
      'impact': 'Rural Education',
      'description': 'Funding books and supplies for village children',
    },
    {
      'name': 'Tree Plantation Drive',
      'goal': 10000,
      'raised': 8500,
      'impact': 'Plant 500 Trees',
      'description': 'Planting trees across Nashik district',
    },
  ];

  Future<Map<String, dynamic>> fetchDonationsAndStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load stats from local storage (or defaults)
      final statsJson = prefs.getString(_statsKey);
      Map<String, dynamic> stats;
      if (statsJson != null) {
        stats = Map<String, dynamic>.from(jsonDecode(statsJson));
      } else {
        // Default starting values for a new user
        stats = {
          'totalCoins': 0,
          'totalCO2': 0,
          'totalDonations': 0,
          'totalWeightKg': 0.0,
        };
      }

      // Load local donation history
      final donationsJson = prefs.getString(_donationsKey);
      List<dynamic> donations = [];
      if (donationsJson != null) {
        donations = jsonDecode(donationsJson) as List<dynamic>;
      }

      return {
        'stats': stats,
        'donations': donations,
        'ngos': _partnerNgos,
      };
    } catch (e) {
      debugPrint('Error loading local donations: $e');
      // Return safe defaults on any error
      return {
        'stats': {
          'totalCoins': 0,
          'totalCO2': 0,
          'totalDonations': 0,
          'totalWeightKg': 0.0,
        },
        'donations': [],
        'ngos': _partnerNgos,
      };
    }
  }

  Future<void> submitDonation({
    required String scrapType,
    required double weightKg,
    String? ngoName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // ── Update Stats ────────────────────────────────────────
    final statsJson = prefs.getString(_statsKey);
    Map<String, dynamic> stats = statsJson != null
        ? Map<String, dynamic>.from(jsonDecode(statsJson))
        : {
            'totalCoins': 0,
            'totalCO2': 0,
            'totalDonations': 0,
            'totalWeightKg': 0.0,
          };

    // Award 10 Eco-Coins per kg donated
    final coinsEarned = (weightKg * 10).toInt();
    // Each kg of scrap = ~1.5 kg CO2 saved
    final co2Saved = (weightKg * 1.5).toStringAsFixed(1);

    stats['totalCoins'] = (stats['totalCoins'] as int) + coinsEarned;
    stats['totalCO2'] =
        ((stats['totalCO2'] as num) + double.parse(co2Saved)).toStringAsFixed(1);
    stats['totalDonations'] = (stats['totalDonations'] as int) + 1;
    stats['totalWeightKg'] =
        ((stats['totalWeightKg'] as num) + weightKg).toStringAsFixed(1);

    await prefs.setString(_statsKey, jsonEncode(stats));

    // ── Save Donation Record ────────────────────────────────
    final donationsJson = prefs.getString(_donationsKey);
    List<dynamic> donations = donationsJson != null
        ? jsonDecode(donationsJson) as List<dynamic>
        : [];

    donations.insert(0, {
      'scrapType': scrapType,
      'weightKg': weightKg,
      'ngoName': ngoName ?? 'General Fund',
      'coinsEarned': coinsEarned,
      'co2Saved': co2Saved,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 donations
    if (donations.length > 50) donations = donations.sublist(0, 50);

    await prefs.setString(_donationsKey, jsonEncode(donations));
  }
}
