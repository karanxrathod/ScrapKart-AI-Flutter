import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

final donateRepositoryProvider = Provider<DonateRepository>((ref) {
  return DonateRepository(ref.watch(apiClientProvider));
});

class DonateRepository {
  final Dio _dio;

  DonateRepository(this._dio);

  Future<Map<String, dynamic>> fetchDonationsAndStats() async {
    try {
      final response = await _dio.get('/donate');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch donations');
    }
  }

  Future<void> submitDonation({
    required String scrapType,
    required double weightKg,
    String? ngoName,
  }) async {
    try {
      await _dio.post('/donate', data: {
        'scrapType': scrapType,
        'weightKg': weightKg,
        'ngoName': ngoName,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit donation');
    }
  }
}
