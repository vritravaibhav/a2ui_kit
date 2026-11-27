import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/playground/common.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/format/decimal.dart';
import 'package:a2ui_kit/src/foundation/icons/lucide.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:flutter/widgets.dart';

final LucideIconNode _star = lucideImport('Star', LucideRelease.playground);

/// The star's path. The icon node strokes it; the playground's `fill-`
/// class fills the same path, so the fill is drawn separately.
final String _starPath = (_star.elements.single as LucidePath).d;

/// The playground `Rating`: five stars for a value from 0 to 5.
///
/// A fractional star is clipped. The number is one decimal, and a review
/// count, when set, follows it.
Widget buildRating(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = RatingProps(props);
  final tokens = playgroundTokens(context);
  final value = _clamp(view.value);
  final text = _fixed(value);
  final dark = A2uiKitScope.themeOf(context).brightness == Brightness.dark;
  final ink = dark ? const Color(0xffffffff) : const Color(0xff000000);
  final filled = tokens.toneColor(A2uiTone.warning);
  final label = view.label;
  final count = view.count;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 6,
    children: [
      if (label != null && label.isNotEmpty)
        Text(
          label,
          style: playgroundText(
            12,
            weight: FontWeight.w500,
            color: tokens.mutedForeground,
          ),
        ),
      Row(
        spacing: 10,
        children: [
          Semantics(
            label: '$text out of 5 stars',
            image: true,
            child: ExcludeSemantics(
              child: Row(
                spacing: 2,
                children: [
                  for (var i = 0; i < 5; i++)
                    _Star(
                      fraction: (value - i).clamp(0, 1).toDouble(),
                      filled: filled,
                      emptyFill: ink.withValues(alpha: .08),
                      emptyStroke: ink.withValues(alpha: .12),
                    ),
                ],
              ),
            ),
          ),
          Text(
            text,
            style: playgroundText(
              14,
              weight: FontWeight.w500,
              color: tokens.foreground,
            ),
          ),
          if (count != null)
            Text(
              '${formatPlaygroundNumber(count)} reviews',
              style: playgroundText(12, color: tokens.mutedForeground),
            ),
        ],
      ),
    ],
  );
}

/// One 16px star, [fraction] of it filled (0 to 1).
class _Star extends StatelessWidget {
  const _Star({
    required this.fraction,
    required this.filled,
    required this.emptyFill,
    required this.emptyStroke,
  });

  final double fraction;
  final Color filled;
  final Color emptyFill;
  final Color emptyStroke;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 16,
    height: 16,
    child: Stack(
      children: [
        _glyph(emptyFill, emptyStroke),
        if (fraction > 0)
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: _glyph(filled, filled),
            ),
          ),
      ],
    ),
  );

  Widget _glyph(Color fill, Color stroke) => Stack(
    children: [
      SvgPathGlyph(pathData: _starPath, size: 16, color: fill),
      LucideGlyph(
        _star,
        size: 16,
        color: const Color(0x00000000),
        stroke: stroke,
        strokeWidth: 1.5,
      ),
    ],
  );
}

/// [value] clamped to 0–5.
double _clamp(double? value) {
  final number = value ?? 0;
  if (!number.isFinite) return 0;
  return number.clamp(0, 5).toDouble();
}

/// One decimal, as JavaScript's `toFixed(1)`.
String _fixed(num value) {
  final negative = value.isNegative;
  final (:whole, :fraction) = roundedDecimalDigits(value.abs(), 1);
  return '${negative ? '-' : ''}$whole.$fraction';
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/catalog/renderers/data.tsx
