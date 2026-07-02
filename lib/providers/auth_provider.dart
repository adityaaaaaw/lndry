import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// OTP verified; new customer must complete profile.
class AuthNeedsProfileSetup extends AuthState {
  const AuthNeedsProfileSetup({required this.phone});
  final String phone;
}

/// Profile complete; needs location permission before address selection.
class AuthNeedsLocationPermission extends AuthState {
  const AuthNeedsLocationPermission({required this.user});
  final UserModel user;
}

/// Location granted; needs default address selection.
class AuthNeedsAddressSelection extends AuthState {
  const AuthNeedsAddressSelection({required this.user});
  final UserModel user;
}

/// Fully authenticated and onboarded.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
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

  final CustomerRepository _repo;
  final StorageService _storage;

  // ── Initialisation (session restore via stored tokens) ──────────────────────

  Future<void> _init() async {
    state = const AuthLoading();

    // One-time session reset for fresh installs (clears stale dev data).
    final resetDone = _storage.getBool('fresh_install_reset_done_v3') ?? false;
    if (!resetDone) {
      await _storage.clearSession();
      await _clearUserPrefs();
      await _storage.saveBool('fresh_install_reset_done_v3', value: true);
    }

    // Try reading stored tokens from secure storage.
    final accessToken = await _storage.getSecure(AppConstants.keyAccessToken);
    final refreshToken = await _storage.getSecure(AppConstants.keyRefreshToken);

    if (accessToken == null && refreshToken == null) {
      state = const AuthUnauthenticated();
      return;
    }

    // Attempt to restore session by refreshing the token pair.
    final hasAddress = _storage.getBool('user_has_address') ?? false;

    try {
      final pair = await _repo.refreshTokens();

      // Store refreshed tokens
      await _storage.saveSecure(AppConstants.keyAccessToken, pair.accessToken);
      await _storage.saveSecure(
          AppConstants.keyRefreshToken, pair.refreshToken);

      // Fetch user profile
      final user = await _repo.getProfile();
      await _saveUserPrefs(user);

      // Handle server-side profile deletion edge case
      if (_needsProfileSetup(user)) {
        state = AuthNeedsProfileSetup(phone: user.phone);
        return;
      }

      _routeAfterAuth(user: user, hasAddress: hasAddress);
    } catch (_) {
      // Token refresh failed — clear everything and go to login.
      await _storage.clearSession();
      await _clearUserPrefs();
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
      await _storage.saveSecure(
          AppConstants.keyAccessToken, result.accessToken);
      await _storage.saveSecure(
          AppConstants.keyRefreshToken, result.refreshToken);
      await _saveUserPrefs(result.user);

      if (result.isNewUser || _needsProfileSetup(result.user)) {
        state = AuthNeedsProfileSetup(phone: result.user.phone);
      } else {
        // Check if address setup is needed
        final hasAddress = _storage.getBool('user_has_address') ?? false;
        _routeAfterAuth(user: result.user, hasAddress: hasAddress);
      }
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

  // ── Profile completion ─────────────────────────────────────────────────────

  /// Saves new customer profile and advances to location-permission.
  Future<void> completeProfile({
    required String name,
    required String email,
  }) async {
    final prev = state;
    final String? phone;
    if (prev is AuthNeedsProfileSetup) {
      phone = prev.phone;
    } else {
      return;
    }

    state = const AuthLoading();
    try {
      // Update profile on backend
      await _repo.updateProfile(UpdateProfileRequest(name: name, email: email));

      final user = UserModel(
        id: '',
        name: name,
        phone: phone,
        email: email,
        role: UserRole.customer,
        isVerified: true,
      );

      // Fetch profile from backend to get the real user object
      UserModel persisted;
      try {
        persisted = await _repo.getProfile();
      } catch (_) {
        persisted = user;
      }

      await _saveUserPrefs(persisted);
      state = AuthNeedsLocationPermission(user: persisted);
    } catch (e) {
      state = AuthError('Failed to save profile. Please try again.');
    }
  }

  // ── Location / Address flow ────────────────────────────────────────────────

  Future<void> completeLocationSetup() async {
    final prev = state;
    if (prev is! AuthNeedsLocationPermission) return;
    state = AuthNeedsAddressSelection(user: prev.user);
  }

  Future<void> completeAddressSelection(AddressModel address) async {
    final prev = state;
    if (prev is! AuthNeedsAddressSelection) return;

    state = const AuthLoading();
    try {
      final savedAddress = await _repo.addAddress(address);
      await _repo.setDefaultAddress(savedAddress.id);
      await _storage.saveBool('user_has_address', value: true);
      await _storage.saveString('user_default_address_id', savedAddress.id);
      state = AuthAuthenticated(prev.user);
    } catch (e) {
      state = AuthError('Failed to save address. Please try again.');
    }
  }

  // ── Profile update (for authenticated users) ───────────────────────────────

  Future<void> updateAuthenticatedUser({
    required String name,
    required String email,
  }) async {
    final prev = state;
    if (prev is! AuthAuthenticated) return;

    try {
      final updated = await _repo.updateProfile(
        UpdateProfileRequest(name: name, email: email),
      );
      await _saveUserPrefs(updated);
      state = AuthAuthenticated(updated);
    } catch (e) {
      // Fallback: update locally if API fails
      final updated = prev.user.copyWith(name: name, email: email);
      await _storage.saveString('user_name', name);
      await _storage.saveString('user_email', email);
      state = AuthAuthenticated(updated);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // Best-effort server-side invalidation
    }
    await _storage.clearSession();
    await _clearUserPrefs();
    state = const AuthUnauthenticated();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _routeAfterAuth({
    required UserModel user,
    required bool hasAddress,
  }) {
    if (!hasAddress) {
      state = AuthNeedsAddressSelection(user: user);
    } else {
      state = AuthAuthenticated(user);
    }
  }

  bool _needsProfileSetup(UserModel user) =>
      user.name.isEmpty && user.email == null;

  Future<void> _saveUserPrefs(UserModel user) async {
    await Future.wait([
      _storage.saveString(AppConstants.keyUserId, user.id),
      _storage.saveString('user_name', user.name),
      _storage.saveString('user_email', user.email ?? ''),
      _storage.saveString('user_phone', user.phone),
    ]);
  }

  Future<void> _clearUserPrefs() async {
    await Future.wait([
      _storage.remove('user_name'),
      _storage.remove('user_email'),
      _storage.remove('user_phone'),
      _storage.remove('user_has_address'),
      _storage.remove('user_default_address_id'),
    ]);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(repo, storage);
});

/// Convenience provider: returns the current authenticated user, or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final s = ref.watch(authProvider);
  return switch (s) {
    AuthAuthenticated(:final user) => user,
    AuthNeedsLocationPermission(:final user) => user,
    AuthNeedsAddressSelection(:final user) => user,
    _ => null,
  };
});
