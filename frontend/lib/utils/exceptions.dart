class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Koneksi internet bermasalah. Coba lagi.',
          code: 'NETWORK_ERROR',
        );
}

class AuthenticationException extends AppException {
  AuthenticationException({String? message})
      : super(
          message: message ?? 'Autentikasi gagal.',
          code: 'AUTH_ERROR',
        );
}

class ValidationException extends AppException {
  ValidationException({String? message})
      : super(
          message: message ?? 'Data tidak valid.',
          code: 'VALIDATION_ERROR',
        );
}