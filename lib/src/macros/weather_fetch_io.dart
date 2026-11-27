import 'dart:convert';
import 'dart:io';

/// Fetches JSON from [uri] with [timeout], for Open-Meteo and Nominatim.
Future<Object?> defaultGetJson(
  Uri uri, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    request.headers
      ..set(HttpHeaders.userAgentHeader, 'a2ui_kit/0.1 (Flutter)')
      ..set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('${uri.host} responded ${response.statusCode}');
    }
    return jsonDecode(body);
  } finally {
    client.close(force: true);
  }
}

// PORT STATUS: confidence=high todos=0 upstream=none
