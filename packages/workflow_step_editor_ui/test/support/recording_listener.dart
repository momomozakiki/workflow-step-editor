/// A hand-written test double (no mock library) that counts how many times it
/// was invoked as a [ChangeNotifier] listener. Mirrors the core project's
/// "hand-rolled fakes" convention.
class RecordingListener {
  int calls = 0;

  /// Pass `listener.call` to `addListener`.
  void call() => calls++;
}

/// A deterministic clock for injection into time-dependent code, so tests never
/// depend on the wall clock.
class FixedClock {
  FixedClock(this._now);

  DateTime _now;

  DateTime call() => _now;

  /// Advance the fixed time by [d].
  void advance(Duration d) => _now = _now.add(d);
}
