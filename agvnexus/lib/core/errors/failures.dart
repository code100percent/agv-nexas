/// Base domain failure class.
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.details});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class RobotDisconnectedFailure extends Failure {
  const RobotDisconnectedFailure([
    super.message = 'Robot telemetry stream disconnected',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}
