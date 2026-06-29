import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../core/services/storage_service.dart';
import '../core/constants/app_constants.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// OTP code has been sent, waiting for user input
class AuthOtpSent extends AuthState {
  const AuthOtpSent({required this.phone, required this.mockCode});
  final String phone;
  final String mockCode;
}

/// User is authenticated but hasn't set up their profile (name, email, etc.)
class AuthNeedsProfileSetup extends AuthState {
  const AuthNeedsProfileSetup({required this.phone});
  final String phone;
}

/// Profile is set up but needs location permission
class AuthNeedsLocationPermission extends AuthState {
  const AuthNeedsLocationPermission({required this.user});
  final UserModel user;
}

/// Location is set up but needs default address map selection
class AuthNeedsAddressSelection extends AuthState {
  const AuthNeedsAddressSelection({required this.user});
  final UserModel user;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthInitial()) {
    _init();
  }

  final StorageService _storage;
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _init() async {
    state = const AuthLoading();

    // Force a one-time clear of old developer bypass sessions for UI review
    final resetDone = _storage.getBool('fresh_install_reset_done_v2') ?? false;
    if (!resetDone) {
      await _storage.clearSession();
      await _storage.remove('user_name');
      await _storage.remove('user_email');
      await _storage.remove('user_phone');
      await _storage.remove('user_has_address');
      await _storage.remove('user_default_address_id');
      await _storage.saveBool('fresh_install_reset_done_v2', value: true);
    }
    
    // Check local storage and Firebase Auth state
    final firebaseUser = _auth?.currentUser;
    final userId = _storage.getString(AppConstants.keyUserId) ?? firebaseUser?.uid;
    final userPhone = _storage.getString('user_phone') ?? firebaseUser?.phoneNumber;
    final hasAddress = _storage.getBool('user_has_address') ?? false;

    if (userId != null) {
      final name = _storage.getString('user_name') ?? firebaseUser?.displayName;
      final email = _storage.getString('user_email') ?? firebaseUser?.email;
      final phone = userPhone ?? 'google_auth';

      if (name == null || name.isEmpty) {
        state = AuthNeedsProfileSetup(phone: phone);
      } else {
        final user = UserModel(
          id: userId,
          name: name,
          phone: phone,
          email: email,
          role: UserRole.customer,
          isVerified: true,
        );

        if (!hasAddress) {
          state = AuthNeedsAddressSelection(user: user);
        } else {
          state = AuthAuthenticated(user);
        }
      }
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Simulates sending an OTP to a phone number.
  Future<void> sendOtp(String phone) async {
    state = const AuthLoading();
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate a fixed mock code for testing ease: "1234"
    state = AuthOtpSent(phone: phone, mockCode: '1234');
  }

  /// Verifies mock OTP code
  Future<void> verifyOtp(String code) async {
    final currentState = state;
    if (currentState is! AuthOtpSent) return;

    state = const AuthLoading();
    await Future.delayed(const Duration(milliseconds: 600));

    if (code == currentState.mockCode) {
      final phone = currentState.phone;

      // Mock DB check: does user exist?
      final savedName = _storage.getString('user_name');

      if (savedName == null || savedName.isEmpty) {
        // New user: must setup profile
        state = AuthNeedsProfileSetup(phone: phone);
      } else {
        // Existing user
        final userId = 'usr_${phone.hashCode}';
        await _storage.saveString(AppConstants.keyUserId, userId);
        await _storage.saveString('user_phone', phone);
        await _storage.saveSecure(AppConstants.keyAccessToken, 'mock_access_token');

        final user = UserModel(
          id: userId,
          name: savedName,
          phone: phone,
          email: _storage.getString('user_email'),
          role: UserRole.customer,
          isVerified: true,
        );

        final hasAddress = _storage.getBool('user_has_address') ?? false;
        if (!hasAddress) {
          state = AuthNeedsAddressSelection(user: user);
        } else {
          state = AuthAuthenticated(user);
        }
      }
    } else {
      state = const AuthError('Invalid OTP code. Please enter 1234.');
      // Revert to OTP screen state
      state = AuthOtpSent(phone: currentState.phone, mockCode: currentState.mockCode);
    }
  }

  /// Submits profile details
  Future<void> completeProfile({
    required String name,
    required String email,
  }) async {
    final currentState = state;
    String? phone;
    if (currentState is AuthNeedsProfileSetup) {
      phone = currentState.phone;
    } else if (currentState is AuthAuthenticated) {
      phone = currentState.user.phone;
    }

    if (phone == null) return;

    state = const AuthLoading();
    await Future.delayed(const Duration(milliseconds: 800));

    final userId = 'usr_${phone.hashCode}';
    await _storage.saveString(AppConstants.keyUserId, userId);
    await _storage.saveString('user_name', name);
    await _storage.saveString('user_email', email);
    await _storage.saveString('user_phone', phone);
    await _storage.saveSecure(AppConstants.keyAccessToken, 'mock_access_token');

    final user = UserModel(
      id: userId,
      name: name,
      phone: phone,
      email: email,
      role: UserRole.customer,
      isVerified: true,
    );

    // Profile complete, proceed to Location Permission screen
    state = AuthNeedsLocationPermission(user: user);
  }

  /// Marks location permissions or selections complete
  Future<void> completeLocationSetup() async {
    final currentState = state;
    UserModel? user;
    if (currentState is AuthNeedsLocationPermission) {
      user = currentState.user;
    }

    if (user == null) return;

    // Proceed to map address selection screen
    state = AuthNeedsAddressSelection(user: user);
  }

  /// Saves selected default address
  Future<void> completeAddressSelection(AddressModel address) async {
    final currentState = state;
    UserModel? user;
    if (currentState is AuthNeedsAddressSelection) {
      user = currentState.user;
    }

    if (user == null) return;

    state = const AuthLoading();
    await Future.delayed(const Duration(milliseconds: 600));

    await _storage.saveBool('user_has_address', value: true);
    await _storage.saveString('user_default_address_id', address.id);

    state = AuthAuthenticated(user);
  }

  /// Authenticates user using Firebase and Google Account Picker
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled account selection
        state = const AuthUnauthenticated();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final authInstance = _auth;
      if (authInstance == null) {
        state = const AuthError('Firebase Auth is not available.');
        return;
      }
      final UserCredential userCredential = await authInstance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final phone = firebaseUser.phoneNumber ?? '';
        final name = firebaseUser.displayName ?? '';
        final email = firebaseUser.email ?? '';
        final userId = firebaseUser.uid;

        // Persist session details
        await _storage.saveString(AppConstants.keyUserId, userId);
        await _storage.saveString('user_name', name);
        if (email.isNotEmpty) {
          await _storage.saveString('user_email', email);
        }
        if (phone.isNotEmpty) {
          await _storage.saveString('user_phone', phone);
        }
        await _storage.saveSecure(AppConstants.keyAccessToken, googleAuth.accessToken ?? 'firebase_google_token');

        final user = UserModel(
          id: userId,
          name: name,
          phone: phone.isNotEmpty ? phone : 'google_auth',
          email: email,
          role: UserRole.customer,
          isVerified: true,
        );

        if (name.isEmpty) {
          state = AuthNeedsProfileSetup(phone: phone.isNotEmpty ? phone : 'google_auth');
        } else {
          final hasAddress = _storage.getBool('user_has_address') ?? false;
          if (!hasAddress) {
            state = AuthNeedsAddressSelection(user: user);
          } else {
            state = AuthAuthenticated(user);
          }
        }
      } else {
        state = const AuthError('Google account mapping in Firebase failed.');
      }
    } catch (e) {
      state = AuthError('Google Sign-In Error: ${e.toString()}');
      state = const AuthUnauthenticated();
    }
  }

  Future<void> logout() async {
    try {
      await _auth?.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
    await _storage.clearSession();
    await _storage.remove('user_name');
    await _storage.remove('user_email');
    await _storage.remove('user_phone');
    await _storage.remove('user_has_address');
    await _storage.remove('user_default_address_id');
    state = const AuthUnauthenticated();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(storage);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated
      ? authState.user
      : authState is AuthNeedsLocationPermission
          ? authState.user
          : authState is AuthNeedsAddressSelection
              ? authState.user
              : null;
});
