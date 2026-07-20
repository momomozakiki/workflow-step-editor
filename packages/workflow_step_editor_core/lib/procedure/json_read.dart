/// Safe readers for **untrusted** decoded JSON (e.g. an imported document file).
///
/// Every method coerces or falls back to a caller-supplied default rather than
/// throwing a raw `TypeError`/cast error on malformed input. This is the
/// input-hardening seam the `fromJson` factories build on — see the
/// `wse-input-hardening` skill. Package-internal (not re-exported from the
/// barrel).
library;

/// Namespace of static, null-safe coercions over decoded JSON values.
final class JsonReader {
  const JsonReader._();

  /// Coerce [value] to a `Map<String, Object?>`; a non-map yields `{}`.
  static Map<String, Object?> asMap(Object? value) => value is Map
      ? value.map((key, dynamic v) => MapEntry(key.toString(), v))
      : const <String, Object?>{};

  /// Coerce [value] to a `String`; anything else yields [fallback].
  static String asString(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  /// Coerce [value] to a 32-bit ARGB int, tolerating an int, a decimal string,
  /// or a `0x`/`#` hex string. Out-of-range ints are masked to 32 bits. Any
  /// unparseable value yields [fallback].
  static int asArgb(Object? value, {required int fallback}) {
    if (value is int) return value & 0xFFFFFFFF;
    if (value is String) {
      final trimmed = value.trim().replaceFirst('#', '');
      final parsed = int.tryParse(trimmed) ?? int.tryParse(trimmed, radix: 16);
      if (parsed != null) return parsed & 0xFFFFFFFF;
    }
    return fallback;
  }

  /// Coerce [value] to a `List<Object?>`; a non-list yields `[]`.
  static List<Object?> asList(Object? value) =>
      value is List ? List<Object?>.from(value) : const <Object?>[];
}
