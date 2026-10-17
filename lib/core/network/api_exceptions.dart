class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'No internet connection. Check your network.']);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Server encountered an error. Please try again later.',
    int? statusCode,
  ]) : super(statusCode: statusCode);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Session expired. Please log in again.'])
      : super(statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Requested resource not found.'])
      : super(statusCode: 404);
}

class CacheException extends ApiException {
  const CacheException([super.message = 'Failed to load cached data.']);
}