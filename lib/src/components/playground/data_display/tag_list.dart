import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/playground/common.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:a2ui_kit/src/theme/playground_tokens.dart';
import 'package:flutter/widgets.dart';

/// The playground `TagList`: a wrapping row of outline chips.
///
/// Each tag is a 24px chip (`h-6`), 12px text, `rounded-md` (8px), with the
/// tone's soft fill and border (default is black/white at 6% / 8%), matching
/// CopilotKit's Badge + `TONE[tone].soft` renderer. Long labels truncate
/// inside the chip. Props may be data bindings.
Widget buildTagList(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = TagListProps(props);
  final tokens = playgroundTokens(context);
  final theme = A2uiKitScope.themeOf(context);
  final tone = view.tone ?? A2uiTone.default_;
  final tags = [
    for (final raw in view.tags)
      if (ComponentProps.unwrap(raw) case final Object value
          when playgroundString(value).isNotEmpty)
        playgroundString(value),
  ];
  if (tags.isEmpty) return const SizedBox.shrink();
  final (fill, ink, border) = _soft(tokens, tone);
  // `rounded-md` → theme md (8px), as on a2ui-playground.copilotkit.ai.
  final radius = BorderRadius.circular(theme.radius('md') ?? 8);
  return Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final tag in tags)
        // `w-fit`: no alignment on the Container (that would expand to the
        // Wrap's max width and stack every chip on its own line).
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              tag,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: playgroundText(
                12,
                weight: FontWeight.w400,
                height: 16 / 12,
                color: ink,
              ),
            ),
          ),
        ),
    ],
  );
}

/// A tone's soft chip: fill, ink and border (TagList's `TONE[tone].soft`).
(Color, Color, Color) _soft(A2uiPlaygroundTokens tokens, A2uiTone tone) {
  if (tone == A2uiTone.default_) {
    final ink = tokens.foreground.withValues(alpha: .85);
    return (
      tokens.ink.withValues(alpha: .06),
      ink,
      tokens.ink.withValues(alpha: .08),
    );
  }
  final color = tokens.toneColor(tone);
  return (
    color.withValues(alpha: tone == A2uiTone.accent ? .14 : .13),
    color,
    color.withValues(alpha: tone == A2uiTone.accent ? .26 : .24),
  );
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/catalog/renderers/data.tsx
