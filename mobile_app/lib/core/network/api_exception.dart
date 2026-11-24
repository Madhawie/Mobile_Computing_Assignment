/// A request failed. [retryable] tells the sync engine whether to send the
/// same batch again later (api.md section 10, "Retry rule").
sealed class ApiFailure implements Exception {
  const ApiFailure(this.message);

  final String message;

  /// true: network error, timeout or 5xx → try again with backoff.
  /// false: 4xx → do not retry automatically.
  bool get retryable;

  /// Short code written to `sync_log.error_code`.
  String get code;
}

/// No answer from the server: no signal, connection dropped, timeout.
/// This is the normal case for a PHM in the field.
class NetworkFailure extends ApiFailure {
  const NetworkFailure(super.message, {this.timedOut = false});

  final bool timedOut;

  @override
  bool get retryable => true;

  @override
  String get code => timedOut ? 'TIMEOUT' : 'NETWORK';

  @override
  String toString() => 'NetworkFailure($code: $message)';
}

/// The server answered with an error (ProblemDetails + `code`).
class HttpFailure extends ApiFailure {
  const HttpFailure(this.status, this.errorCode, super.message);

  final int status;

  /// e.g. `TOKEN_EXPIRED`, `BATCH_TOO_LARGE`, `PHONE_NOT_REGISTERED`.
  final String errorCode;

  @override
  bool get retryable => status >= 500;

  @override
  String get code => errorCode;

  bool get tokenExpired => status == 401 && errorCode == 'TOKEN_EXPIRED';

  @override
  String toString() => 'HttpFailure($status $errorCode: $message)';
}
