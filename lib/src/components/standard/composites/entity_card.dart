import 'dart:async';
import 'dart:math' as math;

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/standard/inputs/controls.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/css/css_length.dart';
import 'package:a2ui_kit/src/foundation/format/decimal.dart';
import 'package:a2ui_kit/src/foundation/interaction/actions.dart';
import 'package:a2ui_kit/src/foundation/interaction/focus_visible.dart';
import 'package:a2ui_kit/src/foundation/interaction/links.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:a2ui_kit/src/theme/a2ui_kit_theme.dart';
import 'package:a2ui_kit/src/theme/tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The standard `EntityCard`: one product, place, person or listing.
///
/// It shows an image, title, subtitle, description, a meta line, a badge,
/// a rating and up to three buttons. A click opens `href`, or sends
/// `onClick` when that is bound. A button opens its own `href`, or sends
/// `onAction` with its label.
Widget buildEntityCard(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = EntityCardProps(props);
  final theme = A2uiKitScope.themeOf(context);
  final title = view.title ?? '';
  final href = safeHref(view.href);
  final clickable = href != null || view.onClick != null;
  final horizontal = view.layout == A2uiOrientation.horizontal;
  final image = view.image;
  final radius = theme.radius('xl') ?? 16;
  final body = _body(context, node, props, view, theme);
  final content = horizontal
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.space(3),
          children: [
            if (image != null && image.isNotEmpty)
              _image(image, title, square: true),
            Expanded(child: body),
          ],
        )
      : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null && image.isNotEmpty)
              _image(image, title, aspect: _aspect(view.imageAspectRatio)),
            body,
          ],
        );
  final card = DecoratedBox(
    decoration: BoxDecoration(
      color: theme.color(A2uiColorToken.surface),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.color(A2uiColorToken.borderDefault)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: content,
    ),
  );
  final framed = clickable
      ? Semantics(
          link: true,
          child: _CardPress(
            borderRadius: BorderRadius.circular(radius),
            onPress: () {
              if (view.onClick != null) {
                unawaited(runActionWithArgs(node, props, 'onClick', {}));
                return;
              }
              if (href != null) unawaited(openSafeUrl(context, href));
            },
            child: card,
          ),
        )
      : card;
  return LayoutBuilder(
    builder: (context, constraints) {
      final max = constraints.maxWidth;
      final asked = A2uiLength.steps(view.width)?.resolve();
      final width = asked == null
          ? (max.isFinite ? max : null)
          : (max.isFinite ? math.min(asked, max) : asked);
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: framed),
      );
    },
  );
}

Widget _body(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  EntityCardProps view,
  A2uiKitTheme theme,
) {
  final title = view.title;
  final subtitle = view.subtitle;
  final description = view.description;
  final meta = view.meta;
  final badge = _badge(view.badge, theme);
  final rating = view.rating;
  final actions = _actions(view.actions);
  return Padding(
    padding: EdgeInsets.all(theme.space(3)),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        if ((subtitle != null && subtitle.isNotEmpty) || badge != null)
          Row(
            spacing: theme.space(2),
            children: [
              if (subtitle != null && subtitle.isNotEmpty)
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(theme, size: _Size.xs, secondary: true),
                  ),
                ),
              ?badge,
            ],
          ),
        if (title != null && title.isNotEmpty)
          Text(
            title,
            style: _text(theme, size: _Size.md, weight: FontWeight.w500),
          ),
        if (rating != null) _rating(theme, rating, view.ratingCount),
        if (description != null && description.isNotEmpty)
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _text(theme, secondary: true),
          ),
        if (meta != null && meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(meta, style: _text(theme, weight: FontWeight.w500)),
          ),
        if (actions.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: theme.space(2)),
            child: Wrap(
              spacing: theme.space(2),
              runSpacing: theme.space(2),
              children: [
                for (final action in actions)
                  _CardButton(
                    action: action,
                    outlined: action.href != null || view.onAction != null,
                    theme: theme,
                    onPressed: () =>
                        unawaited(_button(context, node, props, action)),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

Future<void> _button(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  _Action action,
) async {
  if (action.href != null) {
    await openSafeUrl(context, action.href!);
    return;
  }
  await runActionWithArgs(node, props, 'onAction', {'label': action.label});
}

Widget _image(String url, String title, {bool square = false, double? aspect}) {
  final image = Image.network(
    url,
    fit: BoxFit.cover,
    semanticLabel: title,
    errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
  );
  if (square) return SizedBox(width: 120, height: 120, child: image);
  return AspectRatio(aspectRatio: aspect ?? 4 / 3, child: image);
}

Widget _rating(A2uiKitTheme theme, double rating, double? count) {
  final clamped = _clamp(rating, 0, 5);
  final filled = clamped.round();
  final text = _fixed(clamped);
  final stars = theme.color(A2uiColorToken.rating);
  final empty = theme.color(A2uiColorToken.borderStrong);
  // A Wrap, not a Row: at 320px and text scale 2 the count (e.g. 12840)
  // would overflow a single line. The React card clips with overflow:
  // hidden; Flutter reports that as an error, so the line wraps instead.
  return Wrap(
    spacing: theme.space(1),
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Semantics(
        label: '$text out of 5',
        child: ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < 5; i++)
                  TextSpan(
                    text: '★',
                    style: TextStyle(
                      color: i < filled ? stars : empty,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
            style: _text(theme, secondary: true),
          ),
        ),
      ),
      Text(text, style: _text(theme, secondary: true)),
      if (count != null)
        Text('(${_plain(count)})', style: _text(theme, secondary: true)),
    ],
  );
}

Widget? _badge(Map<String, Object?>? badge, A2uiKitTheme theme) {
  if (badge == null) return null;
  final label = badge['label'];
  if (label is! String || label.isEmpty) return null;
  final named = badge['color'];
  final color = named is String ? named : null;
  final background =
      theme.backgroundColor(color ?? 'surface-secondary') ??
      theme.color(A2uiColorToken.surfaceSecondary);
  final foreground =
      theme.textColor(color ?? 'default') ??
      theme.color(A2uiColorToken.textDefault);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(9999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Text(
        label,
        style: _text(
          theme,
          size: _Size.xs,
          weight: FontWeight.w500,
          color: foreground,
        ),
      ),
    ),
  );
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.action,
    required this.outlined,
    required this.theme,
    required this.onPressed,
  });

  final _Action action;
  final bool outlined;
  final A2uiKitTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final variant = _variant(action.variant, outlined: outlined);
    final colors = _buttonColors(theme, variant);
    return Activatable(
      onActivate: onPressed,
      borderRadius: BorderRadius.circular(9999),
      child: Semantics(
        button: true,
        label: action.label,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                action.label,
                textAlign: TextAlign.start,
                style: _text(
                  theme,
                  weight: FontWeight.w500,
                  color: colors.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enter and Space activate the card only while it itself is focused, so a
/// button inside it keeps the key.
class _CardPress extends StatefulWidget {
  const _CardPress({
    required this.onPress,
    required this.child,
    required this.borderRadius,
  });

  final VoidCallback onPress;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<_CardPress> createState() => _CardPressState();
}

class _CardPressState extends State<_CardPress> {
  late final FocusNode _node = FocusNode(debugLabel: 'a2ui EntityCard');
  late final FocusVisibility _focus = FocusVisibility(_node)
    ..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_changed)
      ..dispose();
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    focusNode: _node,
    mouseCursor: SystemMouseCursors.click,
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          if (_node.hasPrimaryFocus) widget.onPress();
          return null;
        },
      ),
    },
    child: _focus.listen(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPress,
        child: FocusRing(
          visible: _focus.visible,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    ),
  );
}

class _Action {
  const _Action(this.label, this.href, this.variant);

  final String label;
  final String? href;
  final String? variant;
}

List<_Action> _actions(List<Object?> raw) {
  final actions = <_Action>[];
  for (final item in raw) {
    if (actions.length == 3) break;
    final value = ComponentProps.unwrap(item);
    if (value is! Map) continue;
    final label = value['label'];
    if (label is! String || label.isEmpty) continue;
    final href = value['href'];
    final variant = value['variant'];
    actions.add(
      _Action(
        label,
        href is String && href.isNotEmpty ? href : null,
        variant is String ? variant : null,
      ),
    );
  }
  return actions;
}

String _variant(String? variant, {required bool outlined}) {
  if (variant == 'solid' ||
      variant == 'soft' ||
      variant == 'outline' ||
      variant == 'ghost') {
    return variant!;
  }
  return outlined ? 'outline' : 'ghost';
}

({Color background, Color foreground, Color border}) _buttonColors(
  A2uiKitTheme theme,
  String variant,
) {
  const none = Color(0x00000000);
  final ink = theme.color(A2uiColorToken.textDefault);
  return switch (variant) {
    'solid' => (
      background: theme.color(A2uiColorToken.accent),
      foreground: theme.color(A2uiColorToken.onAccent),
      border: none,
    ),
    'soft' => (
      background: theme.color(A2uiColorToken.surfaceSecondary),
      foreground: ink,
      border: none,
    ),
    'outline' => (
      background: none,
      foreground: ink,
      border: theme.color(A2uiColorToken.borderDefault),
    ),
    _ => (background: none, foreground: ink, border: none),
  };
}

double _aspect(String text) {
  final parts = text.split('/');
  if (parts.length != 2) return 4 / 3;
  final width = double.tryParse(parts[0].trim());
  final height = double.tryParse(parts[1].trim());
  if (width == null || height == null || width <= 0 || height <= 0) {
    return 4 / 3;
  }
  return width / height;
}

double _clamp(double value, double min, double max) {
  if (!value.isFinite) return min;
  return value.clamp(min, max);
}

String _fixed(num value) {
  final negative = value.isNegative;
  final (:whole, :fraction) = roundedDecimalDigits(value.abs(), 1);
  return '${negative ? '-' : ''}$whole.$fraction';
}

String _plain(num value) {
  if (value == value.roundToDouble() && value.abs() < 1e21) {
    return '${value.toInt()}';
  }
  return '$value';
}

enum _Size { xs, sm, md }

TextStyle _text(
  A2uiKitTheme theme, {
  _Size size = _Size.sm,
  bool secondary = false,
  FontWeight? weight,
  Color? color,
}) {
  final (fontSize, height) = switch (size) {
    _Size.xs => (12.0, 1.333),
    _Size.sm => (14.0, 1.429),
    _Size.md => (16.0, 1.625),
  };
  return TextStyle(
    fontSize: fontSize,
    height: height,
    fontWeight: weight,
    color:
        color ??
        theme.color(
          secondary ? A2uiColorToken.textSecondary : A2uiColorToken.textDefault,
        ),
  );
}

// PORT STATUS: confidence=high todos=0 upstream=packages/react-core/src/v2/generative-ui/standard/composites.tsx
