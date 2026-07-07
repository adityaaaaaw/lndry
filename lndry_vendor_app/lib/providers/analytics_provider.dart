import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/repositories.dart';

/// Period selector state for the analytics page.
final analyticsPeriodProvider = StateProvider.autoDispose<String>((ref) => 'week');

/// Fetches computed analytics summary from the repository for the current period.
/// Automatically refetches when the period changes.
final analyticsStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final period = ref.watch(analyticsPeriodProvider);
  final repo = ref.watch(vendorRepositoryProvider);
  return repo.getAnalyticsSummary(period: period);
});
