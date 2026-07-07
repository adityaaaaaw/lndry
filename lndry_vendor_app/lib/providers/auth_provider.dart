import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../core/services/storage_service.dart';
import '../core/constants/app_constants.dart';
import '../core/network/network.dart';
import '../repositories/repositories.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

/// App just launched; determining session state.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Any async auth operation is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP sent; waiting for user to enter code.
class AuthOtpSent extends AuthState {
  const AuthOtpSent({
    required this.phone,
    required this.challengeId,
    this.devOtp,
  });

  final String phone;

  /// Backend challenge ID for this OTP session.
  final String challengeId;

  /// Dev-only OTP value (populated in mock/dev mode; null in production).
  final String? devOtp;
}

/// OTP verified; vendor authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.vendor);
  final VendorModel vendor;
}

/// Not signed in; needs login.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed; [message] is safe to display.
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo, this._storage) : super(const AuthInitial()) {
    _init();
  }

  final VendorRepository _repo;
  final StorageService _storage;

  // ── Initialisation (session restore via stored tokens) ──────────────────────

  Future<void> _init() async {
    state = const AuthLoading();

    // One-time session reset for fresh installs (clears stale dev data).
    final resetDone = _storage.getBool('vendor_fresh_install_reset_done_v1') ?? false;
    if (!resetDone) {
      await _storage.clearSession();
      await _clearVendorPrefs();
      await _storage.saveBool('vendor_fresh_install_reset_done_v1', value: true);
    }

    // Try reading stored tokens from secure storage.
    final accessToken = await _storage.getSecure(AppConstants.keyAccessToken);
    final refreshToken = await _storage.getSecure(AppConstants.keyRefreshToken);

    if (accessToken == null && refreshToken == null) {
      state = const AuthUnauthenticated();
      return;
    }

    // Attempt to restore session by refreshing the token pair.
    try {
      final pair = await _repo.refreshTokens();

      // Store refreshed tokens
      await _storage.saveSecure(AppConstants.keyAccessToken, pair.accessToken);
      await _storage.saveSecure(AppConstants.keyRefreshToken, pair.refreshToken);

      // Fetch vendor profile
      final vendor = await _repo.getProfile();
      await _saveVendorPrefs(vendor);
      await _registerDeviceIfPossible();

      state = AuthAuthenticated(vendor);
    } catch (_) {
      // Token refresh failed — clear everything and go to login.
      await _storage.clearSession();
      await _clearVendorPrefs();
      state = const AuthUnauthenticated();
    }
  }

  // ── OTP flow ───────────────────────────────────────────────────────────────

  /// Requests an OTP for [phone] via the active repository.
  Future<void> sendOtp(String phone) async {
    state = const AuthLoading();
    try {
      final result = await _repo.sendOtp(phone);
      state = AuthOtpSent(
        phone: phone,
        challengeId: result.challengeId,
        devOtp: result.devOtp,
      );
    } catch (e) {
      state = AuthError(
        e is ApiException ? e.message : 'Failed to send OTP. Please try again.',
      );
    }
  }

  /// Verifies OTP [code] against the active challenge.
  Future<void> verifyOtp(String code) async {
    final prev = state;
    if (prev is! AuthOtpSent) return;

    state = const AuthLoading();
    try {
      final result = await _repo.verifyOtp(
        phone: prev.phone,
        otp: code,
        challengeId: prev.challengeId,
      );

      // Persist tokens
      await _storage.saveSecure(AppConstants.keyAccessToken, result.accessToken);
      await _storage.saveSecure(AppConstants.keyRefreshToken, result.refreshToken);
      await _saveVendorPrefs(result.vendor);
      await _registerDeviceIfPossible();

      state = AuthAuthenticated(result.vendor);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Verification failed. Please try again.');
    }
  }

  /// Restores [AuthOtpSent] for the previous phone after an error.
  void restoreOtpState(String phone, String challengeId, {String? devOtp}) {
    state = AuthOtpSent(phone: phone, challengeId: challengeId, devOtp: devOtp);
  }

  /// Clears a transient error back to unauthenticated.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  // ── Profile update (for authenticated vendors) ───────────────────────────────

  Future<void> updateAuthenticatedVendor({
    required String name,
    required String email,
  }) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return;

    try {
      final updated = await _repo.updateProfile(
        name: name,
        email: email,
      );
      await _saveVendorPrefs(updated);
      state = AuthAuthenticated(updated);
    } catch (e) {
      // Fallback: update locally if API fails
      final updated = prev.vendor.copyWith(name: name, email: email);
      await _storage.saveString('vendor_name', name);
      await _storage.saveString('vendor_email', email);
      state = AuthAuthenticated(updated);
    }
  }

  Future<void> toggleStoreOpen(bool isOpen) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return;
    final updated = await _repo.toggleStoreOpen(isOpen);
    state = AuthAuthenticated(updated);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    await updateAuthenticatedVendor(name: name, email: email);
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final deviceId = _storage.getString('device_id');
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        await _repo.unregisterDevice(deviceId);
      } catch (_) {}
    }
    try {
      await _repo.logout();
    } catch (_) {
      // Best-effort server-side invalidation
    }
    await _storage.clearSession();
    await _clearVendorPrefs();
    state = const AuthUnauthenticated();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _saveVendorPrefs(VendorModel vendor) async {
    await Future.wait([
      _storage.saveString(AppConstants.keyUserId, vendor.id),
      _storage.saveString('vendor_name', vendor.name),
      _storage.saveString('vendor_email', vendor.email ?? ''),
      _storage.saveString('vendor_phone', vendor.phone),
    ]);
  }

  Future<void> _clearVendorPrefs() async {
    await Future.wait([
      _storage.remove('vendor_name'),
      _storage.remove('vendor_email'),
      _storage.remove('vendor_phone'),
    ]);
  }

  Future<void> _registerDeviceIfPossible() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      var deviceId = _storage.getString('device_id');
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = const Uuid().v4();
        await _storage.saveString('device_id', deviceId);
      }

      final platform = Platform.isAndroid
          ? 'ANDROID'
          : Platform.isIOS
              ? 'IOS'
              : 'UNKNOWN';
      await _repo.registerDevice(
        deviceId: deviceId,
        platform: platform,
        fcmToken: token,
      );
    } catch (_) {
      // Firebase config is optional for local/dev builds; auth must continue.
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(repo, storage);
});

/// Convenience provider: returns the current authenticated vendor, or null.
final currentVendorProvider = Provider<VendorModel?>((ref) {
  final s = ref.watch(authProvider);
  return switch (s) {
    AuthAuthenticated(:final vendor) => vendor,
    _ => null,
  };
});
