String? validateEmail(String value) {
  final email = value.trim();
  if (email.isEmpty) return 'Enter your email.';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  if (!ok) return 'Enter a valid email.';
  return null;
}

String? validateLoginPassword(String value) {
  if (value.isEmpty) return 'Enter your password.';
  return null;
}

String? validateNewPassword(String value) {
  if (value.length < 8) return 'Use at least 8 characters.';
  if (value.length > 128) return 'Use at most 128 characters.';
  return null;
}
