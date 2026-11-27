import 'package:a2ui_kit/a2ui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlightCard', () {
    test('expands the official Pacific Air sample', () {
      final components = expandMacroSample('FlightCard');
      expect(components, isNotEmpty);
      expect(components.first['id'], 'root');
      expect(components.first['component'], 'Card');

      final texts = _texts(components);
      expect(texts, contains('Pacific Air'));
      expect(texts, contains('PA 214 · Economy'));
      expect(texts, contains('SFO'));
      expect(texts, contains('JFK'));
      expect(texts, contains('San Francisco'));
      expect(texts, contains('New York'));
      expect(texts, contains('07:15'));
      expect(texts, contains('15:52'));
      expect(texts, contains('5h 37m'));
      expect(texts, contains('Nonstop'));
      expect(texts, contains('Cheapest'));
      expect(texts, contains(r'$289'));
      expect(texts, contains('Thu, Nov 13'));
      expect(texts, contains('Select flight'));

      final ids = [for (final c in components) c['id']];
      expect(ids, contains('root'));
      expect(ids, contains('root__row_1'));
      expect(ids, contains('root__badge_1'));
      expect(ids, contains('root__button_1'));
      expect(ids, contains('root__divider_1'));

      final button = components.firstWhere((c) => c['component'] == 'Button');
      expect(button['onClick'], {
        'event': {
          'name': 'select_flight',
          'context': {'flight': 'PA 214'},
        },
      });
    });

    test('keeps a bound stops value as a calc', () {
      final tree = expandFlightCard({
        'airline': 'Pacific Air',
        'from': 'SFO',
        'to': 'JFK',
        'depart': '07:15',
        'arrive': '15:52',
        'stops': {'@path': '/stops'},
      });
      final flat = flatten('root', tree);
      final badge = flat.firstWhere((c) {
        final label = c['label'];
        return c['component'] == 'Badge' &&
            label is Map &&
            label['@call'] == 'calc';
      });
      expect(badge['label'], {
        '@call': 'calc',
        'args': {
          'v': {'@path': '/stops'},
          'expression': "v == 0 ? 'Nonstop' : v == 1 ? '1 stop' : v + ' stops'",
        },
      });
      expect(badge['color'], {
        '@call': 'calc',
        'args': {
          'v': {'@path': '/stops'},
          'expression': "v == 0 ? 'success' : 'warning'",
        },
      });
    });
  });

  group('WeatherReport', () {
    test('expands the Lisbon sample forecast', () {
      final components = expandMacroSample('WeatherReport');
      expect(components.first['id'], 'root');
      expect(components.first['component'], 'Card');

      final texts = _texts(components);
      expect(texts, contains('Lisbon, Portugal'));
      expect(texts, contains('19°C'));
      expect(texts, contains('Partly cloudy'));
      expect(texts, contains('H 20° · L 15°'));
      expect(texts, contains('Feels like'));
      expect(texts, contains('18°'));
      expect(texts, contains('Humidity'));
      expect(texts, contains('64%'));
      expect(texts, contains('Wind'));
      expect(texts, contains('14 km/h'));
      expect(texts, contains('Today'));
      expect(texts, contains('Fri'));
      expect(texts, contains('Wed'));
      expect(texts.any((t) => t.contains('Live from Open-Meteo')), isTrue);

      final chart = components.firstWhere((c) => c['component'] == 'Chart');
      expect(chart['chartType'], 'area');
      expect(chart['title'], 'Next 12 hours');
      expect(chart['showLegend'], isFalse);
      final data = chart['data']! as List;
      expect(data, hasLength(12));
      expect(data.first, {'time': '14:00', 'temp': 17});
      expect(data.last, {'time': '01:00', 'temp': 15});

      final list = components.firstWhere((c) => c['component'] == 'List');
      expect(list['marker'], 'none');
      final items = list['items']! as List;
      expect(items, hasLength(7));
      expect(items.first, {
        'label': 'Today',
        'value': '15° / 20°',
        'description': 'Partly cloudy, 10% rain',
        'icon': 'cloud-sun',
      });
      expect(items[3], {
        'label': 'Sun',
        'value': '16° / 19°',
        'description': 'Rain, 70% rain',
        'icon': 'cloud-rain',
      });
    });

    test('converts temperatures when unit is F', () {
      final flat = flatten(
        'root',
        expandWeatherReport({
          'location': 'Lisbon',
          'unit': 'F',
        }, sampleLisbonWeather),
      );
      final texts = _texts(flat);
      expect(texts, contains('66°F'));
      final chart = flat.firstWhere((c) => c['component'] == 'Chart');
      expect((chart['series']! as List).first, {
        'key': 'temp',
        'label': 'Temperature (°F)',
      });
    });
  });

  group('MacroExpander', () {
    test('expandSync rejects WeatherReport without a load', () {
      expect(
        () => a2uiKitMacros.expandSync([weatherReportSampleCall]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('loads data'),
          ),
        ),
      );
    });
  });
}

Set<String> _texts(List<Map<String, Object?>> components) {
  final out = <String>{};
  void walk(Object? value) {
    if (value is String) {
      out.add(value);
    } else if (value is Map) {
      value.values.forEach(walk);
    } else if (value is List) {
      value.forEach(walk);
    }
  }

  components.forEach(walk);
  return out;
}
