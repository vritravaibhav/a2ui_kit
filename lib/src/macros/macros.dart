// A port of CopilotKit's FlightCard and WeatherReport macros (macros.ts at
// commit ff6f3b03). ProductCard is left to the server.

import 'package:a2ui_kit/src/macros/macro.dart';
import 'package:a2ui_kit/src/macros/weather.dart';
import 'package:a2ui_kit/src/macros/weather_fetch.dart';

const _weatherIcons = <String, String>{
  'sun': 'sun',
  'cloud-sun': 'cloud-sun',
  'cloud': 'cloud',
  'fog': 'cloud-fog',
  'drizzle': 'cloud-drizzle',
  'rain': 'cloud-rain',
  'snow': 'cloud-snow',
  'storm': 'cloud-lightning',
};

String _weatherIcon(String key) => _weatherIcons[key] ?? 'cloud';

/// Flight itinerary: airline, codes, times, duration, stops, price and a
/// select button. Expands into Card, Row, Column, Title, Text, Caption,
/// Icon, Badge, Button and Divider.
MacroNode expandFlightCard(Map<String, Object?> p) {
  final stops = derive(p['stops'], (v) {
    final n = (v as num).toInt();
    if (n == 0) return 'Nonstop';
    if (n == 1) return '1 stop';
    return '$n stops';
  }, "v == 0 ? 'Nonstop' : v == 1 ? '1 stop' : v + ' stops'");
  final stopsColor = derive(
    p['stops'],
    (v) => (v as num).toInt() == 0 ? 'success' : 'warning',
    "v == 0 ? 'success' : 'warning'",
  );
  final meta = join(' · ', [p['flightNumber'], p['cabin']]);
  MacroNode end(Object? code, Object? time, Object? city, String align) => h(
    'Column',
    {'gap': 0.5, 'align': align},
    h('Title', {'text': code, 'size': 'xl'}),
    h('Text', {'text': time, 'fontWeight': 'semibold', 'tabularNums': true}),
    given(city) ? h('Caption', {'text': city}) : null,
  );
  return h(
    'Card',
    {'gap': 3},
    h(
      'Row',
      {'justify': 'spaceBetween', 'align': 'center', 'gap': 3},
      h(
        'Row',
        {'align': 'center', 'gap': 2.5},
        h('Icon', {'name': 'plane', 'size': 'lg', 'color': 'primary'}),
        h(
          'Column',
          {'gap': 0},
          h('Title', {'text': p['airline'], 'size': 'sm'}),
          given(meta) ? h('Caption', {'text': meta}) : null,
        ),
      ),
      given(p['badge'])
          ? h('Badge', {
              'label': p['badge'],
              'color': 'success',
              'variant': 'soft',
            })
          : null,
    ),
    h(
      'Row',
      {'justify': 'spaceBetween', 'align': 'center', 'gap': 3},
      end(p['from'], p['depart'], p['fromCity'], 'start'),
      h(
        'Column',
        {'gap': 1, 'align': 'center'},
        given(p['duration']) ? h('Caption', {'text': p['duration']}) : null,
        h('Icon', {'name': 'arrow-right', 'color': 'secondary'}),
        given(p['stops'])
            ? h('Badge', {
                'label': stops,
                'color': stopsColor,
                'variant': 'soft',
                'size': 'sm',
              })
            : null,
      ),
      end(p['to'], p['arrive'], p['toCity'], 'end'),
    ),
    h('Divider'),
    h(
      'Row',
      {'justify': 'spaceBetween', 'align': 'center', 'gap': 3},
      h(
        'Column',
        {'gap': 0},
        given(p['date']) ? h('Caption', {'text': p['date']}) : null,
        given(p['price'])
            ? h('Title', {'text': p['price'], 'size': 'lg'})
            : null,
      ),
      given(p['onAction'])
          ? h('Button', {
              'label': p['actionLabel'] ?? 'Select flight',
              'variant': 'primary',
              'size': 'sm',
              'onClick': p['onAction'],
            })
          : null,
    ),
  );
}

/// Live weather for a place: current conditions, a 12-hour chart and a
/// 7-day forecast. [weather] is the forecast (fetched or a sample).
MacroNode expandWeatherReport(Map<String, Object?> p, Weather weather) {
  final f = p['unit'] == 'F';
  int t(num c) => (f ? (c * 9) / 5 + 32 : c).round();
  final today = weather.daily.isEmpty ? null : weather.daily.first;
  MacroNode fact(String label, String value) => h(
    'Column',
    {'gap': 0},
    h('Caption', {'text': label}),
    h('Text', {'text': value, 'fontWeight': 'semibold', 'tabularNums': true}),
  );
  final unit = f ? 'F' : 'C';
  return h(
    'Card',
    {'gap': 4},
    h(
      'Row',
      {'justify': 'spaceBetween', 'align': 'start', 'gap': 3},
      h(
        'Column',
        {'gap': 1},
        h(
          'Row',
          {'align': 'center', 'gap': 1},
          h('Icon', {'name': 'map-pin', 'size': 'sm', 'color': 'secondary'}),
          h('Caption', {
            'text': '${weather.place.name}, ${weather.place.country}',
          }),
        ),
        h('Title', {'text': '${t(weather.current.temp)}°$unit', 'size': '4xl'}),
        h('Text', {'text': weather.current.condition, 'fontWeight': 'medium'}),
        today != null
            ? h('Caption', {'text': 'H ${t(today.max)}° · L ${t(today.min)}°'})
            : null,
      ),
      h('Icon', {
        'name': _weatherIcon(weather.current.icon),
        'size': 'xl',
        'color': 'warning',
      }),
    ),
    h(
      'Row',
      {'justify': 'spaceBetween', 'gap': 3},
      fact('Feels like', '${t(weather.current.feels)}°'),
      fact('Humidity', '${weather.current.humidity}%'),
      fact('Wind', '${weather.current.wind} km/h'),
    ),
    h('Chart', {
      'chartType': 'area',
      'title': 'Next 12 hours',
      'data': [
        for (final x in weather.hourly.take(12))
          {'time': x.label, 'temp': t(x.temp)},
      ],
      'xKey': 'time',
      'series': [
        {'key': 'temp', 'label': 'Temperature (°$unit)'},
      ],
      'height': 150,
      'showLegend': false,
    }),
    h('List', {
      'marker': 'none',
      'items': [
        for (final d in weather.daily)
          {
            'label': d.label,
            'value': '${t(d.min)}° / ${t(d.max)}°',
            'description': d.precip > 0
                ? '${d.condition}, ${d.precip}% rain'
                : d.condition,
            'icon': _weatherIcon(d.icon),
          },
      ],
    }),
    h('Caption', {
      'text':
          'Live from Open-Meteo, updated '
          '${_clock(weather.current.time)} local time',
    }),
  );
}

String _clock(String time) => time.length >= 16 ? time.substring(11, 16) : time;

/// The FlightCard macro definition (no network).
final MacroDefinition flightCardMacro = MacroDefinition(
  name: 'FlightCard',
  expand: (props, _) => expandFlightCard(props),
);

/// The WeatherReport macro definition. Its `load` fetches Open-Meteo.
final MacroDefinition weatherReportMacro = MacroDefinition(
  name: 'WeatherReport',
  load: (props) => fetchWeather('${props['location']}'),
  expand: (props, data) => expandWeatherReport(props, data! as Weather),
);

/// Expands FlightCard and WeatherReport into standard components.
final MacroExpander a2uiKitMacros = MacroExpander([
  flightCardMacro,
  weatherReportMacro,
]);

/// The official FlightCard sample call (Pacific Air PA 214).
const Map<String, Object?> flightCardSampleCall = {
  'id': 'root',
  'component': 'FlightCard',
  'airline': 'Pacific Air',
  'flightNumber': 'PA 214',
  'cabin': 'Economy',
  'from': 'SFO',
  'fromCity': 'San Francisco',
  'to': 'JFK',
  'toCity': 'New York',
  'depart': '07:15',
  'arrive': '15:52',
  'duration': '5h 37m',
  'stops': 0,
  'date': 'Thu, Nov 13',
  'price': r'$289',
  'badge': 'Cheapest',
  'onAction': {
    'event': {
      'name': 'select_flight',
      'context': {'flight': 'PA 214'},
    },
  },
};

/// The official WeatherReport sample call (Lisbon).
const Map<String, Object?> weatherReportSampleCall = {
  'id': 'root',
  'component': 'WeatherReport',
  'location': 'Lisbon',
};

/// Expands the official [name] sample into standard components. WeatherReport
/// uses [sampleLisbonWeather], with no network.
List<Map<String, Object?>> expandMacroSample(String name) {
  switch (name) {
    case 'FlightCard':
      return a2uiKitMacros.expandSync([flightCardSampleCall]).components;
    case 'WeatherReport':
      return flatten(
        'root',
        expandWeatherReport({'location': 'Lisbon'}, sampleLisbonWeather),
      );
    default:
      throw ArgumentError.value(name, 'name', 'unknown macro sample');
  }
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/macros/macros.ts
