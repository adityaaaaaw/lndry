/// LNDRY Validation utilities
abstract final class Validators {
  Validators._();

  // ── Phone ─────────────────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  // ── Email ─────────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Email is optional — only validates format when a value is present.
  static String? emailOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ── Name ──────────────────────────────────────────────────────────────────
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 60) return 'Name must be under 60 characters';
    return null;
  }

  // ── OTP ───────────────────────────────────────────────────────────────────
  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (value.trim().length != length) return 'Enter the $length-digit OTP';
    if (!RegExp(r'^\d+$').hasMatch(value.trim())) return 'OTP must be numeric';
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final base = password(value);
    if (base != null) return base;
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // ── Required ──────────────────────────────────────────────────────────────
  static String? Function(String?) required(String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  // ── Min / Max length ──────────────────────────────────────────────────────
  static String? Function(String?) minLength(String fieldName, int min) {
    return (String? value) {
      if (value != null && value.trim().length < min) {
        return '$fieldName must be at least $min characters';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(String fieldName, int max) {
    return (String? value) {
      if (value != null && value.trim().length > max) {
        return '$fieldName must be under $max characters';
      }
      return null;
    };
  }

  // ── Pincode ───────────────────────────────────────────────────────────────
  static String? pincode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  // ── Amount ────────────────────────────────────────────────────────────────
  static String? amount(String? value, {double min = 0}) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed < min) return 'Amount must be at least ₹${min.toStringAsFixed(0)}';
    return null;
  }

  // ── GST Number ────────────────────────────────────────────────────────────
  static String? gstNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$')
        .hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid GST number';
    }
    return null;
  }

  // ── Compose multiple validators ───────────────────────────────────────────
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
