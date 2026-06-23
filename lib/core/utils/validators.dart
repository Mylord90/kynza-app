abstract class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email requis.';
    final pattern = RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\-.]+$');
    if (!pattern.hasMatch(v.trim())) return 'Email invalide.';
    return null;
  }

  /// 8+ chars, 1 uppercase, 1 digit.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis.';
    if (v.length < 8) return '8 caractères minimum.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return '1 majuscule minimum.';
    if (!RegExp(r'\d').hasMatch(v)) return '1 chiffre minimum.';
    return null;
  }

  /// 8 digits, Burundi format (without the +257 prefix).
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Numéro requis.';
    if (!RegExp(r'^\d{8}$').hasMatch(v.trim())) {
      return 'Numéro invalide (8 chiffres).';
    }
    return null;
  }

  static String? required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName requis.';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Confirmation requise.';
    if (v != original) return 'Les mots de passe ne correspondent pas.';
    return null;
  }

  static String? fullName(String? v) => required(v, 'Nom complet');

  static String? firstName(String? v) => required(v, 'Prénom');
}
