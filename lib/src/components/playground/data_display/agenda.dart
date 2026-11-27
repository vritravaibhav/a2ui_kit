import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/playground/common.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/icons/lucide.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/theme/playground_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The playground `Agenda`: days of timed events in a card.
///
/// A `title` (13px semibold) heads the card. Each day is a 48px date
/// column (the `label`, else the en-US weekday, the day, and the month)
/// beside its events. An event is a well with a 2px tone bar (the chart
/// palette in turn when `tone` is missing), a 64px time ("All day" when
/// unset), the title, an
/// optional speaker and a wrapping description, and a location with a map
/// pin. Event title, speaker, description and location wrap to as many
/// lines as they need (the React port truncated some of those to one or
/// two lines). A day with no events says "Nothing scheduled". A
/// `YYYY-MM-DD` date is local midnight. Props may be data bindings; the
/// catalog resolves them before this builds.
Widget buildAgenda(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = AgendaProps(props);
  final tokens = playgroundTokens(context);
  final title = view.title;
  final days = [for (final raw in view.days) ?_map(raw)];
  return InlineSizeContainer(
    inset: 34,
    child: Container(
      decoration: playgroundCardDecoration(tokens),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null && title.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.line)),
              ),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: playgroundText(
                    13,
                    weight: FontWeight.w600,
                    trackingEm: -.025,
                    height: 1.25,
                    color: tokens.foreground,
                  ),
                ),
              ),
            ),
          for (final (index, day) in days.indexed)
            _AgendaDay(
              day: day,
              tokens: tokens,
              divided: index > 0,
              eventOffset: _eventsBefore(days, index),
            ),
        ],
      ),
    ),
  );
}

/// One day of an [buildAgenda]: the date column and its event wells.
class _AgendaDay extends StatelessWidget {
  const _AgendaDay({
    required this.day,
    required this.tokens,
    required this.divided,
    required this.eventOffset,
  });

  final Map<String, Object?> day;
  final A2uiPlaygroundTokens tokens;
  final bool divided;

  /// How many events the earlier days hold, so a missing tone keeps
  /// walking the palette across day boundaries.
  final int eventOffset;

  @override
  Widget build(BuildContext context) {
    final date = _agendaDate(day['date']);
    final label = _text(day['label']);
    final events = [for (final raw in _list(day['events'])) ?_map(raw)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: divided
          ? BoxDecoration(
              border: Border(top: BorderSide(color: tokens.line)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: [
                  Text(
                    label ?? (date == null ? '' : _weekday.format(date)),
                    textAlign: TextAlign.center,
                    style: playgroundText(
                      12.5,
                      weight: FontWeight.w500,
                      height: 1.25,
                      color: tokens.mutedForeground,
                    ),
                  ),
                  Text(
                    date == null
                        ? playgroundString(ComponentProps.unwrap(day['date']))
                        : '${date.day}',
                    textAlign: TextAlign.center,
                    style: playgroundText(
                      22,
                      weight: FontWeight.w600,
                      height: 1.25,
                      trackingEm: -.025,
                      tabular: true,
                      color: tokens.foreground,
                    ),
                  ),
                  if (date != null)
                    Text(
                      _month.format(date),
                      textAlign: TextAlign.center,
                      style: playgroundText(11, color: tokens.mutedForeground),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nothing scheduled',
                      style: playgroundText(
                        12.5,
                        color: tokens.mutedForeground,
                      ),
                    ),
                  ),
                for (final (index, event) in events.indexed) ...[
                  if (index > 0) const SizedBox(height: 6),
                  _AgendaEvent(
                    event: event,
                    tokens: tokens,
                    colorIndex: eventOffset + index,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One event well: the tone bar, the time, and the text.
class _AgendaEvent extends StatelessWidget {
  const _AgendaEvent({
    required this.event,
    required this.tokens,
    required this.colorIndex,
  });

  final Map<String, Object?> event;
  final A2uiPlaygroundTokens tokens;

  /// Place in the agenda, used when the event names no tone.
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final tone = A2uiTone.fromWire(ComponentProps.unwrap(event['tone']));
    final bar = tone == null
        ? _paletteAt(tokens, colorIndex)
        : tokens.toneColor(tone);
    final timeValue = event.containsKey('time')
        ? ComponentProps.unwrap(event['time'])
        : null;
    final time = timeValue == null ? 'All day' : playgroundString(timeValue);
    final speaker = _text(event['speaker']);
    final description = _text(event['description']);
    final location = _text(event['location']);
    final muted = playgroundText(11.5, color: tokens.mutedForeground);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.ink.withValues(alpha: .03),
        border: Border.all(color: tokens.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              decoration: BoxDecoration(
                color: bar,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  time,
                  style: playgroundText(
                    11.5,
                    weight: FontWeight.w500,
                    tabular: true,
                    color: tokens.mutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playgroundString(ComponentProps.unwrap(event['title'])),
                    style: playgroundText(
                      13,
                      weight: FontWeight.w500,
                      color: tokens.foreground,
                    ),
                  ),
                  if (speaker != null && speaker.isNotEmpty)
                    Text(speaker, style: muted),
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: playgroundText(
                        11.5,
                        height: 1.375,
                        color: tokens.mutedForeground,
                      ),
                    ),
                  if (location != null && location.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: LucideGlyph(
                            lucideImport('MapPin', LucideRelease.playground),
                            size: 12,
                            color: tokens.mutedForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: playgroundText(
                              11,
                              color: tokens.mutedForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final DateFormat _weekday = DateFormat('EEE', 'en_US');
final DateFormat _month = DateFormat('MMM', 'en_US');

final RegExp _dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// The playground's `parseDate`: a `YYYY-MM-DD` is local midnight; anything
/// else `Date` can read is local too. A number is read as its decimal text,
/// which is not a timestamp.
DateTime? _agendaDate(Object? value) {
  final raw = ComponentProps.unwrap(value);
  if (raw is! String && raw is! num) return null;
  final text = raw is String ? raw : playgroundString(raw);
  final parsed = DateTime.tryParse(
    _dateOnly.hasMatch(text) ? '${text}T00:00:00' : text,
  );
  return parsed;
}

Map<String, Object?>? _map(Object? raw) {
  final value = ComponentProps.unwrap(raw);
  if (value is! Map) return null;
  return {for (final entry in value.entries) '${entry.key}': entry.value};
}

List<Object?> _list(Object? raw) {
  final value = ComponentProps.unwrap(raw);
  return value is List ? value : const [];
}

/// Events rendered before [dayIndex], so a missing tone walks `tokens.chart`
/// through the whole agenda rather than restarting each day.
int _eventsBefore(List<Map<String, Object?>> days, int dayIndex) {
  var count = 0;
  for (var i = 0; i < dayIndex; i++) {
    count += [for (final raw in _list(days[i]['events'])) ?_map(raw)].length;
  }
  return count;
}

/// The chart colour at [index], wrapping. An empty palette falls back to
/// the accent.
Color _paletteAt(A2uiPlaygroundTokens tokens, int index) {
  final palette = tokens.chart;
  if (palette.isEmpty) return tokens.toneColor(A2uiTone.accent);
  return palette[index % palette.length];
}

String? _text(Object? raw) {
  final value = ComponentProps.unwrap(raw);
  if (value == null) return null;
  return playgroundString(value);
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/catalog/renderers/data.tsx
