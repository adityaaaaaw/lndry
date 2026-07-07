import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StorageService provider
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'StorageService must be overridden in ProviderScope overrides.',
  );
});

/// SharedPreferences provider — initialized before runApp
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in ProviderScope overrides.',
  );
});

/// Unified storage service combining SharedPreferences (non-sensitive)
/// and FlutterSecureStorage (sensitive data like tokens).
class StorageService {
  StorageService({
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        _secure = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  // ── SharedPreferences (non-sensitive) ─────────────────────────────────────

  Future<bool> saveString(String key, String value) =>
      _prefs.setString(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> saveBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> saveInt(String key, int value) =>
      _prefs.setInt(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> saveDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> saveStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clearAll() => _prefs.clear();

  bool containsKey(String key) => _prefs.containsKey(key);

  // ── FlutterSecureStorage (sensitive) ──────────────────────────────────────

  Future<void> saveSecure(String key, String value) =>
      _secure.write(key: key, value: value);

  Future<String?> getSecure(String key) => _secure.read(key: key);

  Future<void> deleteSecure(String key) => _secure.delete(key: key);

  Future<void> deleteAllSecure() => _secure.deleteAll();

  Future<Map<String, String>> getAllSecure() => _secure.readAll();

  // ── Convenience ───────────────────────────────────────────────────────────

  Future<void> clearSession() async {
    await Future.wait([
      deleteSecure('access_token'),
      deleteSecure('refresh_token'),
      remove('user_id'),
      remove('user_role'),
    ]);
  }
}
