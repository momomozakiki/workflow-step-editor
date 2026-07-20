/// A party (role) that a procedure step is assigned to — the colored badge in
/// the editor.
///
/// Pure-Dart and immutable. Colors are stored as **32-bit ARGB ints**, never a
/// Flutter `Color`, so the core stays Flutter-free (see the
/// `wse-package-boundaries` skill); the UI converts to/from `Color`.
library;

import 'json_read.dart';

/// Immutable role badge: a display [name] plus [backgroundArgb]/[textArgb].
final class Party {
  const Party({
    required this.name,
    required this.backgroundArgb,
    required this.textArgb,
  });

  final String name;
  final int backgroundArgb;
  final int textArgb;

  /// Fallback colors for an unrecognised / custom party.
  static const int defaultBackgroundArgb = 0xFFEEF3FA;
  static const int defaultTextArgb = 0xFF1F4870;

  // Presets matching the source HTML template.
  static const Party buyer =
      Party(name: 'BUYER', backgroundArgb: 0xFFD4E2FF, textArgb: 0xFF003D8C);
  static const Party seller =
      Party(name: 'SELLER', backgroundArgb: 0xFFDDF0E6, textArgb: 0xFF006B3E);
  static const Party terminalOperator = Party(
    name: 'TERMINAL OPERATOR',
    backgroundArgb: 0xFFFFF0D6,
    textArgb: 0xFF8A5A00,
  );
  static const Party both =
      Party(name: 'BOTH', backgroundArgb: 0xFFE8E0F5, textArgb: 0xFF4A2D7A);

  /// The default reusable palette.
  static const List<Party> presets = [buyer, seller, terminalOperator, both];

  Party copyWith({String? name, int? backgroundArgb, int? textArgb}) => Party(
        name: name ?? this.name,
        backgroundArgb: backgroundArgb ?? this.backgroundArgb,
        textArgb: textArgb ?? this.textArgb,
      );

  Map<String, Object?> toJson() => {
        'name': name,
        'backgroundArgb': backgroundArgb,
        'textArgb': textArgb,
      };

  /// Build a [Party] from untrusted decoded JSON, defaulting every missing or
  /// malformed field rather than throwing. See [JsonReader].
  factory Party.fromJson(Object? json) {
    final map = JsonReader.asMap(json);
    return Party(
      name: JsonReader.asString(map['name'], fallback: 'PARTY'),
      backgroundArgb:
          JsonReader.asArgb(map['backgroundArgb'], fallback: defaultBackgroundArgb),
      textArgb: JsonReader.asArgb(map['textArgb'], fallback: defaultTextArgb),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Party &&
      other.name == name &&
      other.backgroundArgb == backgroundArgb &&
      other.textArgb == textArgb;

  @override
  int get hashCode => Object.hash(name, backgroundArgb, textArgb);

  @override
  String toString() =>
      'Party($name, bg: 0x${backgroundArgb.toRadixString(16)}, '
      'text: 0x${textArgb.toRadixString(16)})';
}
