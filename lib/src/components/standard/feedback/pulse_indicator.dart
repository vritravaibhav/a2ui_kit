import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:a2ui_kit/src/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// The standard `PulseIndicator`: a small dot with a pulsing ring.
///
/// A `size`px (12) filled disc in `color` (default success). A ring of
/// `pulseColor` (else the same) scales 1→`endScale` (2.4) while fading
/// `startOpacity` (.6)→0 over `duration` (1500ms) ease-out, forever. With
/// reduced motion the ring is omitted and the disc is still. `label` makes
/// it an image for screen readers; without a label it is hidden.
Widget buildPulseIndicator(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = PulseIndicatorProps(props);
  final theme = A2uiKitScope.themeOf(context);
  final size = view.size.isFinite && view.size > 0 ? view.size : 12.0;
  final color =
      theme.textColor(view.color) ?? theme.color(A2uiColorToken.successSolid);
  final pulse =
      theme.textColor(view.pulseColor) ??
      (view.pulseColor != null
          ? (theme.backgroundColor(view.pulseColor) ?? color)
          : color);
  final reduced = MediaQuery.disableAnimationsOf(context);
  final Widget dot;
  if (reduced) {
    // Still disc, no ticker: prefers-reduced-motion and widget tests that
    // call pumpAndSettle.
    dot = _disc(size, color);
  } else {
    dot = _PulseDot(
      size: size,
      color: color,
      pulseColor: pulse,
      durationMs: view.duration.isFinite && view.duration > 0
          ? view.duration
          : 1500,
      endScale: view.endScale.isFinite && view.endScale > 0
          ? view.endScale
          : 2.4,
      startOpacity: view.startOpacity.isFinite
          ? view.startOpacity.clamp(0.0, 1.0)
          : 0.6,
    );
  }
  final label = view.label;
  if (label == null) {
    return ExcludeSemantics(child: dot);
  }
  return Semantics(
    image: true,
    label: label,
    child: ExcludeSemantics(child: dot),
  );
}

Widget _disc(double size, Color color) => SizedBox(
  width: size,
  height: size,
  child: DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  ),
);

class _PulseDot extends StatefulWidget {
  const _PulseDot({
    required this.size,
    required this.color,
    required this.pulseColor,
    required this.durationMs,
    required this.endScale,
    required this.startOpacity,
  });

  final double size;
  final Color color;
  final Color pulseColor;
  final double durationMs;
  final double endScale;
  final double startOpacity;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.durationMs.round()),
  )..repeat();

  @override
  void didUpdateWidget(covariant _PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationMs != widget.durationMs) {
      _controller
        ..duration = Duration(milliseconds: widget.durationMs.round())
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // ease-out: 1 - (1-t)^2, matching CSS ease-out.
          final t = _controller.value;
          final eased = 1 - (1 - t) * (1 - t);
          final scale = 1 + (widget.endScale - 1) * eased;
          final opacity = widget.startOpacity * (1 - eased);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: _disc(size, widget.pulseColor),
                ),
              ),
              _disc(size, widget.color),
            ],
          );
        },
      ),
    );
  }
}

// PORT STATUS: confidence=high todos=0 upstream=packages/react-core/src/v2/generative-ui/standard/feedback.tsx
