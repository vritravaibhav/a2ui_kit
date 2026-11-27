// A port of CopilotKit's getWeather / geocode (agent/apis.ts at ff6f3b03).

import 'package:a2ui_kit/src/macros/weather.dart';
import 'package:a2ui_kit/src/macros/weather_fetch_stub.dart'
    if (dart.library.io) 'package:a2ui_kit/src/macros/weather_fetch_io.dart'
    as http;

/// Fetches JSON from a URL. Used by [fetchWeather]; tests inject a fake.
typedef A2uiJsonGet = Future<Object?> Function(Uri uri, {Duration timeout});

const _wmo = <int, (String, String)>{
  0: ('Clear sky', 'sun'),
  1: ('Mainly clear', 'sun'),
  2: ('Partly cloudy', 'cloud-sun'),
  3: ('Overcast', 'cloud'),
  45: ('Fog', 'fog'),
  48: ('Rime fog', 'fog'),
  51: ('Light drizzle', 'drizzle'),
  53: ('Drizzle', 'drizzle'),
  55: ('Heavy drizzle', 'drizzle'),
  61: ('Light rain', 'rain'),
  63: ('Rain', 'rain'),
  65: ('Heavy rain', 'rain'),
  66: ('Freezing rain', 'rain'),
  67: ('Freezing rain', 'rain'),
  71: ('Light snow', 'snow'),
  73: ('Snow', 'snow'),
  75: ('Heavy snow', 'snow'),
  77: ('Snow grains', 'snow'),
  80: ('Rain showers', 'rain'),
  81: ('Rain showers', 'rain'),
  82: ('Violent showers', 'rain'),
  85: ('Snow showers', 'snow'),
  86: ('Snow showers', 'snow'),
  95: ('Thunderstorm', 'storm'),
  96: ('Thunderstorm, hail', 'storm'),
  99: ('Thunderstorm, hail', 'storm'),
};

/// Maps an Open-Meteo WMO code to a condition and icon key.
(String, String) describeWmo(int code) => _wmo[code] ?? ('Unknown', 'cloud');

num _num(Object? value) {
  if (value is num) return value;
  if (value is String) return num.parse(value);
  throw FormatException('expected a number, got $value');
}

int _int(Object? value) => _num(value).round();

Future<WeatherPlace> _geocode(String place, A2uiJsonGet getJson) async {
  final query = place.length > 200 ? place.substring(0, 200) : place;
  if (query.contains(',')) {
    try {
      final rows = await getJson(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeComponent(query)}'
          '&format=jsonv2&limit=1&addressdetails=1&accept-language=en',
        ),
        timeout: const Duration(seconds: 5),
      );
      if (rows is List && rows.isNotEmpty) {
        final r = rows.first as Map;
        final address = r['address'];
        final addr = address is Map ? address : const <Object?, Object?>{};
        return WeatherPlace(
          name: (r['name'] as String?)?.isNotEmpty == true
              ? r['name']! as String
              : query.split(',').first.trim(),
          country: (addr['country'] as String?) ?? '',
          admin: (addr['city'] as String?) ?? (addr['state'] as String?),
          lat: _num(r['lat']).toDouble(),
          lon: _num(r['lon']).toDouble(),
        );
      }
    } on Object {
      // Fall back to Open-Meteo.
    }
  }
  final q = query.split(',').first.trim();
  final json = await getJson(
    Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeComponent(q)}&count=1&language=en&format=json',
    ),
  );
  if (json is! Map) {
    throw StateError('Could not find a place called "$query"');
  }
  final results = json['results'];
  if (results is! List || results.isEmpty) {
    throw StateError('Could not find a place called "$query"');
  }
  final r = results.first as Map;
  return WeatherPlace(
    name: r['name']! as String,
    country: r['country']! as String,
    admin: r['admin1'] as String?,
    lat: _num(r['latitude']).toDouble(),
    lon: _num(r['longitude']).toDouble(),
    timezone: r['timezone'] as String?,
  );
}

/// Fetches a live forecast for [location] from Open-Meteo. Nominatim is used
/// only when the place contains a comma. Pass [getJson] to stub the network.
Future<Weather> fetchWeather(String location, {A2uiJsonGet? getJson}) async {
  final get = getJson ?? http.defaultGetJson;
  final place = await _geocode(location, get);
  final json = await get(
    Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${place.lat}&longitude=${place.lon}'
      '&current=temperature_2m,apparent_temperature,'
      'relative_humidity_2m,wind_speed_10m,weather_code,is_day'
      '&hourly=temperature_2m,precipitation_probability,weather_code'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_probability_max,sunrise,sunset'
      '&timezone=auto&forecast_days=7',
    ),
  );
  if (json is! Map) {
    throw StateError('Open-Meteo returned no forecast for "$location"');
  }
  final body = json;
  final current = body['current']! as Map;
  final hourly = body['hourly']! as Map;
  final daily = body['daily']! as Map;
  final now = current['time']! as String;
  final times = (hourly['time']! as List).cast<String>();
  var startIdx = times.indexWhere(
    (t) => t.compareTo(now.substring(0, 13)) >= 0,
  );
  if (startIdx < 0) startIdx = 0;
  final temps = hourly['temperature_2m']! as List;
  final precips = hourly['precipitation_probability']! as List;
  final codes = hourly['weather_code']! as List;
  final hourPoints = <WeatherHour>[];
  final end = (startIdx + 24).clamp(0, times.length);
  for (var i = startIdx; i < end; i++) {
    final t = times[i];
    hourPoints.add(
      WeatherHour(
        time: t,
        label: t.length >= 16 ? t.substring(11, 16) : t,
        temp: _int(temps[i]),
        precip: i < precips.length ? (_num(precips[i] ?? 0)) : 0,
        icon: describeWmo(_int(codes[i])).$2,
      ),
    );
  }
  final dayTimes = (daily['time']! as List).cast<String>();
  final dayMins = daily['temperature_2m_min']! as List;
  final dayMaxs = daily['temperature_2m_max']! as List;
  final dayPrecips = daily['precipitation_probability_max']! as List;
  final dayCodes = daily['weather_code']! as List;
  final days = <WeatherDay>[];
  for (var i = 0; i < dayTimes.length; i++) {
    final d = dayTimes[i];
    final described = describeWmo(_int(dayCodes[i]));
    days.add(
      WeatherDay(
        date: d,
        label: i == 0 ? 'Today' : _weekday(DateTime.parse('${d}T12:00:00')),
        min: _int(dayMins[i]),
        max: _int(dayMaxs[i]),
        precip: i < dayPrecips.length ? (_num(dayPrecips[i] ?? 0)) : 0,
        condition: described.$1,
        icon: described.$2,
      ),
    );
  }
  final described = describeWmo(_int(current['weather_code']));
  final sunrises = daily['sunrise'];
  final sunsets = daily['sunset'];
  String? sliceTime(Object? list) {
    if (list is! List || list.isEmpty) return null;
    final s = list.first as String?;
    if (s == null || s.length < 16) return s;
    return s.substring(11, 16);
  }

  return Weather(
    place: place,
    current: WeatherCurrent(
      temp: _int(current['temperature_2m']),
      feels: _int(current['apparent_temperature']),
      humidity: _int(current['relative_humidity_2m']),
      wind: _int(current['wind_speed_10m']),
      code: _int(current['weather_code']),
      condition: described.$1,
      icon: described.$2,
      isDay: current['is_day'] == 1,
      time: now,
    ),
    hourly: hourPoints,
    daily: days,
    sunrise: sliceTime(sunrises),
    sunset: sliceTime(sunsets),
  );
}

String _weekday(DateTime date) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[date.weekday - 1];
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/agent/apis.ts
