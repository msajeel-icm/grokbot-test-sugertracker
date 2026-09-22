/// Failure from the sugar tracker API or the transport in front of it.
class ApiException implements Exception {
  ApiException({this.statusCode, required this.message});

  final int? statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Turns a FastAPI error body into a short message.
String messageFromBody(Object? body, int status) {
  final detail = _detail(body);
  if (detail != null && detail.isNotEmpty) return detail;
  return switch (status) {
    401 => 'Your session expired. Sign in again.',
    409 => 'Email already registered.',
    _ => 'Something went wrong ($status).',
  };
}

String? _detail(Object? body) {
  if (body is! Map) return null;
  final detail = body['detail'];
  if (detail is String) return detail.trim();
  if (detail is List) {
    final messages = <String>[];
    for (final item in detail) {
      if (item is String && item.trim().isNotEmpty) {
        messages.add(item.trim());
      } else if (item is Map && item['msg'] is String) {
        final msg = (item['msg'] as String).trim();
        if (msg.isNotEmpty) messages.add(msg);
      }
    }
    if (messages.isNotEmpty) return messages.join('\n');
  }
  return null;
}
