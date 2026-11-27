import 'dart:async';

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_kit/src/components/node_guard.dart' show isDrawnChild;
import 'package:a2ui_kit/src/components/standard/inputs/controls.dart';
import 'package:a2ui_kit/src/components/standard/layout/container_css.dart';
import 'package:a2ui_kit/src/components/standard/layout/containers.dart';
import 'package:a2ui_kit/src/components/standard/layout/flex_container.dart';
import 'package:a2ui_kit/src/components/standard/layout/grid.dart';
import 'package:a2ui_kit/src/document/props.g.dart';
import 'package:a2ui_kit/src/foundation/icons/lucide.dart';
import 'package:a2ui_kit/src/foundation/interaction/visible_once.dart';
import 'package:a2ui_kit/src/foundation/node_watch.dart';
import 'package:a2ui_kit/src/foundation/scope.dart';
import 'package:a2ui_kit/src/theme/a2ui_kit_theme.dart';
import 'package:a2ui_kit/src/theme/tokens.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

/// The standard `CarouselItem`: one slide of a [buildCarousel].
///
/// A vertical flex container sized by its content (`flex: 0 0 auto`).
/// `onVisible` fires once the slide shows.
Widget buildCarouselItem(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final position = CardScope.of(context);
  final css = containerCss(context, props);
  containerDefaults(css, props, position);
  css.direction = Axis.vertical;
  return flexContainer(
    context,
    props: props,
    css: css,
    children: CarouselItemProps(props).children,
    buildChild: buildChild,
    childPosition: position.child,
  );
}

/// The standard `Carousel`: a horizontal snap scroller with arrows.
///
/// Gap defaults to 8px. Scrollbars are hidden. Binding `activeIndex`
/// smooth-scrolls to that slide; scrolling (debounced 120ms) writes the
/// nearest slide's index. Arrow buttons (32px, inset 4px) fade in when
/// the track can move that way. `snap` defaults to proximity: after a
/// scroll settles, the nearest slide's left edge is brought into view
/// (`none` skips that settle). `visibleItems` and `snapAlign` are unused,
/// as in CopilotKit.
Widget buildCarousel(
  BuildContext context,
  KitNode node,
  ComponentProps props,
  ChildWidgetBuilder buildChild,
) {
  final view = CarouselProps(props);
  final position = CardScope.of(context);
  final css = containerCss(context, props);
  containerDefaults(css, props, position);
  if (!css.hasGap) css.gap = css.steps(2);
  final gap = _gapPx(css);
  final children = view.children.where(isDrawnChild).toList();
  Widget content = _CarouselTrack(
    node: node,
    props: props,
    view: view,
    children: children,
    buildChild: buildChild,
    gap: gap,
  );
  content = CardScope(position: position.child, child: gridBox(css, content));
  final onVisible = view.onVisible;
  if (onVisible != null) {
    content = VisibleOnce(
      onVisible: () => unawaited(onVisible()),
      child: content,
    );
  }
  final label = view.label;
  return Semantics(
    container: true,
    label: label,
    explicitChildNodes: true,
    child: content,
  );
}

double _gapPx(ContainerCss css) {
  final gap = css.gap;
  if (gap == null) return 8;
  return gap.resolve(fontSize: css.fontSize) ?? 8;
}

class _CarouselTrack extends StatefulWidget {
  const _CarouselTrack({
    required this.node,
    required this.props,
    required this.view,
    required this.children,
    required this.buildChild,
    required this.gap,
  });

  final KitNode node;
  final ComponentProps props;
  final CarouselProps view;
  final List<KitNode> children;
  final ChildWidgetBuilder buildChild;
  final double gap;

  @override
  State<_CarouselTrack> createState() => _CarouselTrackState();
}

class _CarouselTrackState extends State<_CarouselTrack> {
  final ScrollController _controller = ScrollController();
  late List<GlobalKey> _keys = [
    for (var i = 0; i < widget.children.length; i++) GlobalKey(),
  ];
  Timer? _debounce;
  bool _canPrev = false;
  bool _canNext = false;
  bool _programmatic = false;
  int? _lastWritten;
  double? _lastPropIndex;

  bool Function(Object? value)? get _write =>
      valueWriter(widget.node, widget.props, 'activeIndex');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateArrows();
      _scrollToPropIndex(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant _CarouselTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length) {
      _keys = [for (var i = 0; i < widget.children.length; i++) GlobalKey()];
      _lastWritten = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateArrows();
      _scrollToPropIndex(animate: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    _updateArrows();
    if (_programmatic) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _settle);
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final prev = position.pixels > position.minScrollExtent + .5;
    final next = position.pixels < position.maxScrollExtent - .5;
    if (prev == _canPrev && next == _canNext) return;
    setState(() {
      _canPrev = prev;
      _canNext = next;
    });
  }

  Future<void> _settle() async {
    if (!mounted || !_controller.hasClients) return;
    final index = _nearestIndex();
    if (index == null) return;
    final snap = widget.view.snap;
    if (snap != CarouselSnap.none) {
      await _scrollToIndex(index, animate: true);
    }
    _commitIndex(index);
  }

  void _commitIndex(int index) {
    if (_lastWritten == index) return;
    _lastWritten = index;
    _write?.call(index.toDouble());
  }

  int? _nearestIndex() {
    if (!_controller.hasClients || widget.children.isEmpty) return null;
    final origin = _trackOrigin();
    if (origin == null) return null;
    final target = _controller.offset;
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _keys.length; i++) {
      final offset = _itemOffset(i, origin);
      if (offset == null) continue;
      final distance = (offset - target).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  double? _trackOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero).dx;
  }

  double? _itemOffset(int index, double origin) {
    final box = _keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero).dx - origin + _controller.offset;
  }

  Future<void> _scrollToIndex(int index, {required bool animate}) async {
    if (!_controller.hasClients || index < 0 || index >= _keys.length) {
      return;
    }
    final origin = _trackOrigin();
    if (origin == null) return;
    final offset = _itemOffset(index, origin);
    if (offset == null) return;
    final clamped = offset.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    if ((clamped - _controller.offset).abs() < .5) return;
    _programmatic = true;
    try {
      if (animate) {
        await _controller.animateTo(
          clamped,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _controller.jumpTo(clamped);
      }
    } finally {
      if (mounted) {
        _programmatic = false;
        _updateArrows();
      }
    }
  }

  void _scrollToPropIndex({required bool animate}) {
    final raw = widget.view.activeIndex;
    if (raw == null || !raw.isFinite) return;
    final index = raw.round().clamp(0, widget.children.length - 1);
    if (_lastPropIndex == raw && animate) {
      // Same binding value the scroller already honoured.
      return;
    }
    // A write-back of the index we just settled on should not re-animate.
    if (_lastWritten != null && index == _lastWritten && animate) {
      _lastPropIndex = raw;
      return;
    }
    _lastPropIndex = raw;
    unawaited(_scrollToIndex(index, animate: animate));
  }

  Future<void> _step(int delta) async {
    final current = _nearestIndex() ?? 0;
    final next = (current + delta).clamp(0, widget.children.length - 1);
    await _scrollToIndex(next, animate: true);
    _commitIndex(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = A2uiKitScope.themeOf(context);
    final showArrows = widget.view.showArrows;
    // A horizontal ListView needs a bounded height; the track is sized by
    // its slides, so a Row inside a SingleChildScrollView matches React.
    // Bounce at the ends the way a browser overflow scroller does on
    // trackpads (CopilotKit's carousel); Material's default clamps on web.
    final track = ScrollConfiguration(
      behavior: const _HiddenScrollbarBehavior(),
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.children.length; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              KeyedSubtree(
                key: _keys[i],
                child: KeyedSubtree(
                  key: NodeKey(widget.children[i].instanceId),
                  child: widget.buildChild(widget.children[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!showArrows || widget.children.isEmpty) return track;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        track,
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: _ArrowButton(
              label: widget.view.previousLabel,
              enabled: _canPrev,
              icon: lucideImport('ChevronLeft', LucideRelease.reactCore),
              theme: theme,
              onPressed: () => unawaited(_step(-1)),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: _ArrowButton(
              label: widget.view.nextLabel,
              enabled: _canNext,
              icon: lucideImport('ChevronRight', LucideRelease.reactCore),
              theme: theme,
              onPressed: () => unawaited(_step(1)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.label,
    required this.enabled,
    required this.icon,
    required this.theme,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final LucideIconNode icon;
  final A2uiKitTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = theme.color(A2uiColorToken.textDefault);
    final fill = theme.color(A2uiColorToken.surfaceElevated);
    final border = theme.color(A2uiColorToken.borderDefault);
    // Semantics stay on the button even while AnimatedOpacity is 0
    // (Opacity hides semantics at 0).
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: IgnorePointer(
            ignoring: !enabled,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? onPressed : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: border),
                  boxShadow: theme.shadow(A2uiShadowToken.sm),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: LucideGlyph(icon, size: 16, color: foreground),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hides scrollbars the way CopilotKit's scroller does (`scrollbar-width:
/// none`), and keeps the rubber-band physics even under Material.
class _HiddenScrollbarBehavior extends ScrollBehavior {
  const _HiddenScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

// PORT STATUS: confidence=high todos=0 upstream=packages/react-core/src/v2/generative-ui/standard/layout.tsx
