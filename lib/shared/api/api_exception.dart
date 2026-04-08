class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, String> fieldErrors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.fieldErrors = const {},
  });

  factory ApiException.fromResponse({
    required int statusCode,
    required dynamic decodedBody,
  }) {
    final body =
        decodedBody is Map<String, dynamic> ? decodedBody : <String, dynamic>{};

    final fallback = _defaultMessageForStatus(statusCode);
    final message = (body['message'] as String?)?.trim().isNotEmpty == true
        ? (body['message'] as String)
        : fallback;

    final fieldErrors = <String, String>{};
    final errors = body['errors'];
    if (errors is Map<String, dynamic>) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          fieldErrors[entry.key] = value.first.toString();
        } else if (value != null) {
          fieldErrors[entry.key] = value.toString();
        }
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      fieldErrors: fieldErrors,
    );
  }

  static String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 422:
        return 'Some fields are invalid. Please review your input.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed. Please try again.';
    }
  }

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
