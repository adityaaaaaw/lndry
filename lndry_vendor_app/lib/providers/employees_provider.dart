import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class EmployeesNotifier extends StateNotifier<AsyncValue<List<EmployeeModel>>> {
  EmployeesNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchEmployees();
  }

  final VendorRepository _repo;

  Future<void> fetchEmployees() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getEmployees();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEmployee({
    required String name,
    required String email,
    required String role,
    String? phone,
    List<String>? permissions,
  }) async {
    try {
      await _repo.createEmployee(
        name: name,
        email: email,
        role: role,
        phone: phone,
        permissions: permissions,
      );
      await fetchEmployees();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEmployee(
    String id, {
    required String role,
    required List<String> permissions,
    required bool isActive,
  }) async {
    try {
      await _repo.updateEmployee(
        id,
        role: role,
        permissions: permissions,
        isActive: isActive,
      );
      await fetchEmployees();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeEmployee(String id) async {
    try {
      await _repo.deleteEmployee(id);
      await fetchEmployees();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String id, String newPassword) async {
    try {
      await _repo.resetEmployeePassword(id, newPassword);
    } catch (e) {
      rethrow;
    }
  }
}

final employeesListProvider = StateNotifierProvider.autoDispose<
    EmployeesNotifier, AsyncValue<List<EmployeeModel>>>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  return EmployeesNotifier(repo);
});
