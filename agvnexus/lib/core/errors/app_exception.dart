/// Standard application exceptions across authentication, database, and repository layers.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

/// Thrown when authentication or session validation fails.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Thrown when an operation is prohibited by RLS or lack of permissions.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([
    super.message = 'Access denied: insufficient organization privileges.',
    String? code = '403',
  ]) : super(code: code);
}

/// Thrown when a requested entity (robot, mission, map) is missing.
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Requested resource was not found.',
    String? code = '404',
  ]) : super(code: code);
}

/// Thrown when database constraints, foreign keys, or queries fail.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

/// Thrown when payload or form validation fails.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Thrown when network transport, HTTP gateway, or WebSocket connectivity fails.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}
