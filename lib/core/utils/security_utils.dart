abstract class SecurityUtils {
  /// Masks all but the first 4 and last 2 digits — e.g. `+25779123456`
  /// becomes `+257***56`.
  static String maskPhone(String phone) {
    if (phone.length < 6) return '***';
    return '${phone.substring(0, 4)}***${phone.substring(phone.length - 2)}';
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';
    final local = parts[0];
    final masked = local.length > 3 ? '${local.substring(0, 3)}***' : '***';
    return '$masked@${parts[1]}';
  }
}
