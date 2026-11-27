/// Default JSON getter off `dart:io`: inject `getJson` into `fetchWeather`.
Future<Object?> defaultGetJson(
  Uri uri, {
  Duration timeout = const Duration(seconds: 8),
}) {
  throw UnsupportedError(
    'fetchWeather needs a getJson on this platform, or expand '
    'WeatherReport with a Weather value',
  );
}

// PORT STATUS: confidence=high todos=0 upstream=none
