import '../core/step_error.dart';

/// A factory closure that builds a fresh `T`.
typedef Factory<T> = T Function();

/// A generic, **instance-based** registry mapping a string `type` to a factory
/// closure. This is the project's Open/Closed + Dependency-Inversion seam:
///
/// - **Open/Closed** — add a new implementation by registering a factory, never
///   by editing a `switch` in the core.
/// - **Dependency Inversion** — the core defines the abstraction; concrete
///   implementations are injected as factories at startup (never imported here).
///
/// Not a global singleton — construct one per app/scope so tests get a fresh,
/// isolated registry. Each [create] call returns a **new** instance.
///
/// ```dart
/// final registry = Registry<MyThing>()
///   ..register('a', MyThingA.new);   // tear-off factory
/// final thing = registry.create('a'); // fresh instance every call
/// ```
class Registry<T> {
  final Map<String, Factory<T>> _factories = {};

  /// Register [factory] under [type]. Throws [ConfigError] if [type] is empty or
  /// already registered (registration is a startup-time programming action, so a
  /// collision is a fatal misconfiguration, not a recoverable one).
  void register(String type, Factory<T> factory) {
    if (type.isEmpty) {
      throw const ConfigError('registry type must not be empty');
    }
    if (_factories.containsKey(type)) {
      throw ConfigError("type '$type' is already registered");
    }
    _factories[type] = factory;
  }

  /// Create a fresh `T` for [type]. Throws [NotFoundError] if [type] is unknown.
  T create(String type) {
    final factory = _factories[type];
    if (factory == null) {
      throw NotFoundError("no factory registered for type '$type'");
    }
    return factory();
  }

  /// Whether [type] has a registered factory.
  bool contains(String type) => _factories.containsKey(type);

  /// The registered type keys, in registration order.
  Iterable<String> get types => _factories.keys;
}
