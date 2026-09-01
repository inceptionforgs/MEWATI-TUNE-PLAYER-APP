class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('Network connection failed');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message);
}