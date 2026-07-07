import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/repositories.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(vendorRepositoryProvider);
  return repo.getDashboardStats();
});
