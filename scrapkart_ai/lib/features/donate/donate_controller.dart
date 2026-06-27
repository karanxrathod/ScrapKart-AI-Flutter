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
    // NGOs are now embedded in the repository - fully offline
    final repository = ref.watch(donateRepositoryProvider);
    return repository.fetchDonationsAndStats();
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
