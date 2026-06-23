/// User-facing exception. The [message] is always already localized/sanitized
/// (e.g. via getAuthErrorMessage) — safe to display directly in the UI.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
