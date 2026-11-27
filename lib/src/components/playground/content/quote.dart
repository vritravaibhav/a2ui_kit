import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/playground/common.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/icons/lucide.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:flutter/widgets.dart';

/// The playground `Quote`: a pull quote with optional attribution.
///
/// A bordered figure with a violet 7% corner gradient, padding 20×16, a
/// faint 32px quote icon at the top-right, 15px medium quote text, and a
/// 12px caption "**author**, role" when `author` is set.
Widget buildQuote(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = QuoteProps(props);
  final tokens = playgroundTokens(context);
  final text = view.text ?? '';
  final author = view.author;
  final role = view.role;
  final radius = BorderRadius.circular(tokens.radius);
  // from-violet-500/[0.07] to transparent (content.tsx Quote).
  const violet = Color(0xff8b5cf6);
  return ClipRRect(
    borderRadius: radius,
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: tokens.line),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  violet.withValues(alpha: .07),
                  violet.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 16,
          child: LucideGlyph(
            lucideImport('Quote', LucideRelease.playground),
            size: 32,
            color: const Color(0xff6d28d9).withValues(alpha: .15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text,
                style: playgroundText(
                  15,
                  weight: FontWeight.w500,
                  height: 1.625,
                  trackingEm: -.025,
                  color: tokens.foreground,
                ),
              ),
              if (author != null && author.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: playgroundText(12, color: tokens.mutedForeground),
                    children: [
                      TextSpan(
                        text: author,
                        style: playgroundText(
                          12,
                          weight: FontWeight.w500,
                          color: tokens.foreground.withValues(alpha: .9),
                        ),
                      ),
                      if (role != null && role.isNotEmpty)
                        TextSpan(text: ', $role'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/catalog/renderers/content.tsx
