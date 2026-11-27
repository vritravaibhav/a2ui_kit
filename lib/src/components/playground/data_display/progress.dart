import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/playground/common.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:flutter/widgets.dart';

/// The playground `Progress`: a labelled bar for a value from 0 to 100.
///
/// The percent is the value rounded to a whole number. The bar fills in the
/// tone's colour (accent when none is set) over a 6px track, and a caption
/// sits under it. The fill moves over 150ms.
Widget buildProgress(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = ProgressProps(props);
  final tokens = playgroundTokens(context);
  final value = _clamp(view.value);
  final tone = view.tone ?? A2uiTone.accent;
  final dark = A2uiKitScope.themeOf(context).brightness == Brightness.dark;
  final track = (dark ? const Color(0xffffffff) : const Color(0xff000000))
      .withValues(alpha: .07);
  final label = view.label;
  final caption = view.caption;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      Row(
        children: [
          if (label != null && label.isNotEmpty)
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: playgroundText(
                  12.5,
                  weight: FontWeight.w500,
                  color: tokens.foreground.withValues(alpha: .9),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          Text(
            '${value.round()}%',
            style: playgroundText(
              12,
              weight: FontWeight.w500,
              color: tokens.mutedForeground,
              tabular: true,
            ),
          ),
        ],
      ),
      ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: SizedBox(
          height: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: track),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value / 100),
                duration: const Duration(milliseconds: 150),
                builder: (context, fraction, child) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: fraction,
                    heightFactor: 1,
                    child: child,
                  ),
                ),
                child: ColoredBox(color: tokens.toneColor(tone)),
              ),
            ],
          ),
        ),
      ),
      if (caption != null && caption.isNotEmpty)
        Text(
          caption,
          style: playgroundText(
            11,
            color: tokens.mutedForeground.withValues(alpha: .8),
          ),
        ),
    ],
  );
}

/// [value] clamped to 0–100, as the playground's `clamp(num(value) ?? 0)`.
double _clamp(double? value) {
  final number = value ?? 0;
  if (!number.isFinite) return 0;
  return number.clamp(0, 100).toDouble();
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/catalog/renderers/data.tsx
