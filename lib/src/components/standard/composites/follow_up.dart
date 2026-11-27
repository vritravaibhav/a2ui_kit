import 'dart:async';

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/standard/inputs/controls.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/interaction/actions.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:a2ui_kit/src/theme/a2ui_kit_theme.dart';
import 'package:a2ui_kit/src/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// The standard `FollowUp`: suggested next prompts as pills.
///
/// A click sends the pill's message. With `onFollowUp` bound, that action
/// runs with the message. Without it, the click sends a `follow_up` event
/// whose user message is the pill.
Widget buildFollowUp(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = FollowUpProps(props);
  final items = [for (final raw in view.items) ?_item(raw)];
  if (items.isEmpty) return const SizedBox.shrink();
  final theme = A2uiKitScope.themeOf(context);
  final title = view.title;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: theme.space(2),
    children: [
      if (title != null && title.isNotEmpty)
        Text(title, style: _text(theme, secondary: true)),
      Wrap(
        spacing: theme.space(2),
        runSpacing: theme.space(2),
        children: [
          for (final item in items)
            _Pill(
              label: item.label,
              onPressed: () => unawaited(_send(node, props, item.message)),
              theme: theme,
            ),
        ],
      ),
    ],
  );
}

Future<void> _send(KitNode node, ComponentProps props, String message) async {
  if (FollowUpProps(props).onFollowUp != null) {
    await runActionWithArgs(node, props, 'onFollowUp', {'message': message});
    return;
  }
  await node.context?.dispatchAction({
    'event': {
      'name': 'follow_up',
      'userMessage': message,
      'context': {'message': message},
    },
  });
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final VoidCallback onPressed;
  final A2uiKitTheme theme;

  @override
  Widget build(BuildContext context) => Activatable(
    onActivate: onPressed,
    borderRadius: BorderRadius.circular(9999),
    child: Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.color(A2uiColorToken.surface),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: theme.color(A2uiColorToken.borderDefault),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              textAlign: TextAlign.start,
              style: _text(theme, weight: FontWeight.w500),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A string item is its own label and message. A map uses `label`, and
/// `message` when it has one.
({String label, String message})? _item(Object? raw) {
  final value = ComponentProps.unwrap(raw);
  if (value is String) {
    if (value.isEmpty) return null;
    return (label: value, message: value);
  }
  if (value is! Map) return null;
  final label = value['label'];
  final message = value['message'];
  final text = label is String ? label : '';
  final sent = message is String && message.isNotEmpty ? message : text;
  if (text.isEmpty || sent.isEmpty) return null;
  return (label: text, message: sent);
}

/// Body text at `sm` (14/20), the pill and title size.
TextStyle _text(
  A2uiKitTheme theme, {
  bool secondary = false,
  FontWeight? weight,
}) => TextStyle(
  fontSize: 14,
  height: 1.429,
  fontWeight: weight,
  color: theme.color(
    secondary ? A2uiColorToken.textSecondary : A2uiColorToken.textDefault,
  ),
);

// PORT STATUS: confidence=high todos=0 upstream=packages/react-core/src/v2/generative-ui/standard/composites.tsx
