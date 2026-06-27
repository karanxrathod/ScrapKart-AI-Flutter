import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'donate_repository.dart';

part 'donate_controller.g.dart';

@riverpod
class DonateController extends _$DonateController {
  @override
  Future<Map<String, dynamic>> build() async {
    return _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final repository = ref.watch(donateRepositoryProvider);
    final data = await repository.fetchDonationsAndStats();
    
    // Add mock NGOs to data
    data['ngos'] = [
      {'name': 'Green Earth NGO', 'goal': 50000, 'raised': 35000, 'impact': 'Ocean Cleanup'},
      {'name': 'Child Education Trust', 'goal': 25000, 'raised': 10000, 'impact': 'Rural Education'},
      {'name': 'Tree Plantation Drive', 'goal': 10000, 'raised': 8500, 'impact': 'Plant 500 Trees'},
    ];
    return data;
  }

  Future<void> submitDonation({
    required String scrapType,
    required double weightKg,
    String? ngoName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(donateRepositoryProvider);
      await repository.submitDonation(
        scrapType: scrapType,
        weightKg: weightKg,
        ngoName: ngoName,
      );
      return _fetchData();
    });
  }
}
