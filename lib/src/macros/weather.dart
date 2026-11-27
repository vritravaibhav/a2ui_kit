// Weather data for WeatherReport, matching CopilotKit's agent/apis.ts
// Weather type at commit ff6f3b03.

/// A geocoded place.
class WeatherPlace {
  /// A named place at [lat], [lon].
  const WeatherPlace({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
    this.admin,
    this.timezone,
  });

  /// The place's short name.
  final String name;

  /// The country name.
  final String country;

  /// An admin region, when known.
  final String? admin;

  /// Latitude.
  final double lat;

  /// Longitude.
  final double lon;

  /// IANA timezone, when known.
  final String? timezone;
}

/// Current conditions at a place.
class WeatherCurrent {
  /// The conditions at [time].
  const WeatherCurrent({
    required this.temp,
    required this.feels,
    required this.humidity,
    required this.wind,
    required this.code,
    required this.condition,
    required this.icon,
    required this.isDay,
    required this.time,
  });

  /// Temperature in °C.
  final num temp;

  /// Feels-like temperature in °C.
  final num feels;

  /// Relative humidity, 0–100.
  final num humidity;

  /// Wind speed in km/h.
  final num wind;

  /// Open-Meteo WMO weather code.
  final int code;

  /// A short English description.
  final String condition;

  /// A lucide key: sun, cloud-sun, cloud, fog, drizzle, rain, snow, storm.
  final String icon;

  /// Whether it is daytime at the place.
  final bool isDay;

  /// Local ISO time, for example `2026-10-29T14:00`.
  final String time;
}

/// One hour of the forecast.
class WeatherHour {
  /// An hour at [time].
  const WeatherHour({
    required this.time,
    required this.label,
    required this.temp,
    required this.precip,
    required this.icon,
  });

  /// Local ISO time.
  final String time;

  /// A short label for the chart axis, for example `14:00`.
  final String label;

  /// Temperature in °C.
  final num temp;

  /// Precipitation probability, 0–100.
  final num precip;

  /// A lucide weather key.
  final String icon;
}

/// One day of the forecast.
class WeatherDay {
  /// A day at [date].
  const WeatherDay({
    required this.date,
    required this.label,
    required this.min,
    required this.max,
    required this.precip,
    required this.condition,
    required this.icon,
  });

  /// ISO date.
  final String date;

  /// A short label: `Today`, `Fri`, …
  final String label;

  /// Low temperature in °C.
  final num min;

  /// High temperature in °C.
  final num max;

  /// Precipitation probability, 0–100.
  final num precip;

  /// A short English description.
  final String condition;

  /// A lucide weather key.
  final String icon;
}

/// A full weather report for one place.
class Weather {
  /// Forecast for [place].
  const Weather({
    required this.place,
    required this.current,
    required this.hourly,
    required this.daily,
    this.sunrise,
    this.sunset,
  });

  /// The geocoded place.
  final WeatherPlace place;

  /// Current conditions.
  final WeatherCurrent current;

  /// Hourly points from now.
  final List<WeatherHour> hourly;

  /// Daily points, typically seven.
  final List<WeatherDay> daily;

  /// Today's sunrise, `HH:MM`, when known.
  final String? sunrise;

  /// Today's sunset, `HH:MM`, when known.
  final String? sunset;
}

WeatherDay _day(
  String label,
  num min,
  num max,
  num precip,
  String condition,
  String icon,
) => WeatherDay(
  date: '',
  label: label,
  min: min,
  max: max,
  precip: precip,
  condition: condition,
  icon: icon,
);

/// The fixed Lisbon forecast the playground uses for WeatherReport previews
/// (CopilotKit's `SAMPLE_WEATHER`).
final Weather sampleLisbonWeather = Weather(
  place: const WeatherPlace(
    name: 'Lisbon',
    country: 'Portugal',
    lat: 38.72,
    lon: -9.14,
  ),
  current: const WeatherCurrent(
    temp: 19,
    feels: 18,
    humidity: 64,
    wind: 14,
    code: 2,
    condition: 'Partly cloudy',
    icon: 'cloud-sun',
    isDay: true,
    time: '2026-10-29T14:00',
  ),
  hourly: const [
    WeatherHour(
      time: '',
      label: '14:00',
      temp: 17,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '15:00',
      temp: 18,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '16:00',
      temp: 19,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '17:00',
      temp: 19,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '18:00',
      temp: 20,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '19:00',
      temp: 19,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '20:00',
      temp: 18,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '21:00',
      temp: 17,
      precip: 5,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '22:00',
      temp: 16,
      precip: 20,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '23:00',
      temp: 16,
      precip: 20,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '00:00',
      temp: 15,
      precip: 20,
      icon: 'cloud-sun',
    ),
    WeatherHour(
      time: '',
      label: '01:00',
      temp: 15,
      precip: 20,
      icon: 'cloud-sun',
    ),
  ],
  daily: [
    _day('Today', 15, 20, 10, 'Partly cloudy', 'cloud-sun'),
    _day('Fri', 14, 21, 0, 'Clear sky', 'sun'),
    _day('Sat', 15, 22, 0, 'Clear sky', 'sun'),
    _day('Sun', 16, 19, 70, 'Rain', 'rain'),
    _day('Mon', 14, 18, 40, 'Drizzle', 'drizzle'),
    _day('Tue', 13, 19, 10, 'Partly cloudy', 'cloud-sun'),
    _day('Wed', 14, 20, 0, 'Mainly clear', 'sun'),
  ],
);

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/agent/apis.ts
