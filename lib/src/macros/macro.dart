// A port of CopilotKit's A2UI macros helper (macro.ts at commit ff6f3b03):
// a high-level call expands into standard components before the client
// renders them. The root keeps the macro's id; every other node is
// `${id}__${type}_${n}`.

/// A dynamic A2UI value: a path binding or a function call.
bool isDynamic(Object? value) =>
    value is Map && (value.containsKey('@path') || value.containsKey('@call'));

/// True when the prop was given: a non-empty literal, or any dynamic value.
bool given(Object? value) {
  if (value == null) return false;
  if (value is String && value.isEmpty) return false;
  if (value is List && value.isEmpty) return false;
  return true;
}

/// One node of an expansion tree. Nested [children] are other nodes, or
/// string ids of components the model already wrote.
class MacroNode {
  /// A [component] with [props] and optional [children].
  MacroNode(this.component, [this.props = const {}, this.children = const []]);

  /// The standard component name.
  final String component;

  /// The props, without nested children.
  final Map<String, Object?> props;

  /// Nested nodes, or ids of components written elsewhere.
  final List<Object> children;
}

/// Builds an expansion tree. Falsy children are skipped.
MacroNode h(
  String component, [
  Map<String, Object?> props = const {},
  Object? c0,
  Object? c1,
  Object? c2,
  Object? c3,
  Object? c4,
  Object? c5,
  Object? c6,
  Object? c7,
  Object? c8,
  Object? c9,
]) {
  final kids = <Object>[];
  for (final c in [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9]) {
    if (c is MacroNode) {
      kids.add(c);
    } else if (c is String) {
      kids.add(c);
    }
  }
  final clean = <String, Object?>{
    for (final e in props.entries)
      if (e.value != null) e.key: e.value,
  };
  return MacroNode(component, clean, kids);
}

/// A literal stays a literal; a bound value becomes a `calc` the renderer
/// evaluates.
Object? derive(
  Object? value,
  Object? Function(Object value) literal,
  String expression, {
  String name = 'v',
}) {
  if (value == null) return null;
  if (isDynamic(value)) {
    return {
      '@call': 'calc',
      'args': {name: value, 'expression': expression},
    };
  }
  return literal(value);
}

/// Joins parts with [sep]. Bound parts become a `formatString` over their
/// paths.
Object? join(String sep, List<Object?> parts) {
  final present = [
    for (final p in parts)
      if (given(p)) p,
  ];
  if (present.isEmpty) return null;
  if (!present.any(isDynamic)) {
    return present.map((p) => p.toString()).join(sep);
  }
  final paths = <String>[];
  for (final p in present) {
    if (isDynamic(p)) {
      final map = p! as Map;
      if (map.containsKey('@path')) {
        paths.add('\${${map['@path']}}');
      } else {
        return present.first;
      }
    } else {
      paths.add(p.toString().replaceAll(r'${', r'\${'));
    }
  }
  return {
    '@call': 'formatString',
    'args': {'value': paths.join(sep)},
  };
}

/// Flattens a tree into A2UI nodes. The root takes [id]; the rest are
/// `${id}__${type}_${n}`.
List<Map<String, Object?>> flatten(String id, MacroNode tree) {
  final out = <Map<String, Object?>>[];
  final counters = <String, int>{};
  void walk(MacroNode node, String nodeId) {
    final flat = <String, Object?>{
      'id': nodeId,
      'component': node.component,
      ...node.props,
    };
    out.add(flat);
    if (node.children.isEmpty) return;
    final ids = <String>[];
    final nested = <(MacroNode, String)>[];
    for (final c in node.children) {
      if (c is String) {
        ids.add(c);
      } else if (c is MacroNode) {
        final type = c.component.toLowerCase();
        final n = (counters[type] ?? 0) + 1;
        counters[type] = n;
        final childId = '${id}__${type}_$n';
        ids.add(childId);
        nested.add((c, childId));
      }
    }
    flat['children'] = ids;
    for (final (c, childId) in nested) {
      walk(c, childId);
    }
  }

  walk(tree, id);
  return out;
}

/// One expanded macro in a list.
class MacroExpansion {
  /// The [id] that held [macro], replaced by [components] nodes.
  const MacroExpansion({
    required this.id,
    required this.macro,
    required this.components,
  });

  /// The macro node's id.
  final String id;

  /// The macro's name.
  final String macro;

  /// How many flat nodes the expansion produced.
  final int components;
}

/// The result of expanding every macro in a component list.
class ExpandedMacros {
  /// The flat [components] after expansion, and what was [expanded].
  const ExpandedMacros({required this.components, required this.expanded});

  /// The component list with macros replaced by their expansions.
  final List<Map<String, Object?>> components;

  /// Each macro that was expanded, in order.
  final List<MacroExpansion> expanded;
}

/// A macro the model may write: props in, a tree of standard components out.
class MacroDefinition {
  /// A named macro.
  const MacroDefinition({required this.name, required this.expand, this.load});

  /// The component name the model writes.
  final String name;

  /// Loads data the expansion needs. Server-side only.
  final Future<Object?> Function(Map<String, Object?> props)? load;

  /// Props (and loaded data) to a tree of standard components.
  final MacroNode Function(Map<String, Object?> props, Object? data) expand;
}

const _maxDepth = 16;

Map<String, Object?> _argsOf(Map<String, Object?> node) => {
  for (final e in node.entries)
    if (e.key != 'id' && e.key != 'component') e.key: e.value,
};

ExpandedMacros _splice(
  List<Map<String, Object?>> components,
  List<List<Map<String, Object?>>?> trees,
) {
  final expanded = <MacroExpansion>[];
  final next = <Map<String, Object?>>[];
  for (var i = 0; i < components.length; i++) {
    final out = trees[i];
    if (out == null) {
      next.add(components[i]);
      continue;
    }
    expanded.add(
      MacroExpansion(
        id: components[i]['id']! as String,
        macro: components[i]['component']! as String,
        components: out.length,
      ),
    );
    next.addAll(out);
  }
  return ExpandedMacros(components: next, expanded: expanded);
}

/// Expands every known macro in a flat component list.
class MacroExpander {
  /// An expander for [macros].
  MacroExpander(List<MacroDefinition> macros)
    : _byName = {for (final m in macros) m.name: m};

  final Map<String, MacroDefinition> _byName;

  /// The registered macro names.
  Iterable<String> get names => _byName.keys;

  /// Whether [component] is a registered macro.
  bool isMacro(Object? component) =>
      component is String && _byName.containsKey(component);

  Future<List<Map<String, Object?>>?> _expandOne(Map<String, Object?> c) async {
    if (!isMacro(c['component'])) return null;
    final m = _byName[c['component']]!;
    final args = _argsOf(c);
    final data = m.load != null ? await m.load!(args) : null;
    return flatten(c['id']! as String, m.expand(args, data));
  }

  /// Expands macros that load no data. A data macro throws.
  ExpandedMacros expandSync(
    List<Map<String, Object?>> components, [
    int depth = 0,
  ]) {
    if (depth > _maxDepth) {
      throw StateError('Macro expansion went deeper than $_maxDepth levels');
    }
    final trees = <List<Map<String, Object?>>?>[];
    for (final c in components) {
      if (!isMacro(c['component'])) {
        trees.add(null);
        continue;
      }
      final m = _byName[c['component']]!;
      if (m.load != null) {
        throw StateError(
          '${m.name} loads data, so it must be expanded with expand()',
        );
      }
      trees.add(flatten(c['id']! as String, m.expand(_argsOf(c), null)));
    }
    final step = _splice(components, trees);
    if (step.expanded.isEmpty) return step;
    final rest = expandSync(step.components, depth + 1);
    return ExpandedMacros(
      components: rest.components,
      expanded: [...step.expanded, ...rest.expanded],
    );
  }

  /// Expands every macro, loading data macros in parallel.
  Future<ExpandedMacros> expand(
    List<Map<String, Object?>> components, [
    int depth = 0,
  ]) async {
    if (depth > _maxDepth) {
      throw StateError('Macro expansion went deeper than $_maxDepth levels');
    }
    final trees = await Future.wait([
      for (final c in components) _expandOne(c),
    ]);
    final step = _splice(components, trees);
    if (step.expanded.isEmpty) return step;
    final rest = await expand(step.components, depth + 1);
    return ExpandedMacros(
      components: rest.components,
      expanded: [...step.expanded, ...rest.expanded],
    );
  }
}

// PORT STATUS: confidence=high todos=0 upstream=examples/showcases/a2ui-playground/src/a2ui/macros/macro.ts
