// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donate_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DonateController)
final donateControllerProvider = DonateControllerProvider._();

final class DonateControllerProvider
    extends $AsyncNotifierProvider<DonateController, Map<String, dynamic>> {
  DonateControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'donateControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$donateControllerHash();

  @$internal
  @override
  DonateController create() => DonateController();
}

String _$donateControllerHash() => r'e553b5b656ce44dbec2da4ca0f8cf37e71dee30e';

abstract class _$DonateController extends $AsyncNotifier<Map<String, dynamic>> {
  FutureOr<Map<String, dynamic>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>,
        AsyncValue<Map<String, dynamic>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
