import 'dart:math';

class PricingService {
  static const Map<String, double> _basePricesPerKg = {
    'Recyclable Plastics': 15.0,
    'Metals': 45.0,
    'Copper': 400.0,
    'Aluminum': 120.0,
    'Iron': 30.0,
    'Paper & Cardboard': 12.0,
    'Electronics': 50.0,
    'Glass': 5.0,
    'Unknown': 10.0,
  };

  static Map<String, dynamic> getEstimatedPrice(String category, double weightKg, double conditionFactor) {
    final double basePrice = _basePricesPerKg[category] ?? 10.0;
    
    // Simulate real-time market fluctuation (-5% to +5%)
    final random = Random();
    final fluctuation = (random.nextDouble() * 0.1) - 0.05;
    
    final double currentMarketPrice = basePrice * (1 + fluctuation);
    final double finalPricePerKg = currentMarketPrice * conditionFactor;
    
    final double totalPrice = finalPricePerKg * weightKg;

    return {
      'pricePerKg': currentMarketPrice.roundToDouble(),
      'totalEstimatedPrice': totalPrice.roundToDouble(),
      'marketTrend': fluctuation, // positive means prices are up
      'trendPercentage': (fluctuation * 100).round(),
    };
  }
}
