/// One row of a procedure: a [title], a [action] description, a [documents]
/// list, the responsible [party], and an optional [icon].
///
/// Pure-Dart and immutable. The step *number* is intentionally **not** stored —
/// it is derived from the row's position in [ProcedureDocument.steps], so adding,
/// removing, or reordering rows renumbers automatically.
library;

import 'json_read.dart';
import 'party.dart';

/// Immutable procedure row.
final class ProcedureStep {
  const ProcedureStep({
    required this.title,
    required this.action,
    required this.documents,
    required this.party,
    this.icon = '',
  });

  final String title;
  final String action;
  final String documents;
  final Party party;

  /// Identifier for the step's display icon (e.g. `'handshake'`), resolved to a
  /// concrete glyph by the UI's icon catalog. Empty means "no icon". Stored as a
  /// plain [String] — never a Flutter type — so the core stays Flutter-free (the
  /// same reason [Party] stores colors as ARGB ints).
  final String icon;

  ProcedureStep copyWith({
    String? title,
    String? action,
    String? documents,
    Party? party,
    String? icon,
  }) =>
      ProcedureStep(
        title: title ?? this.title,
        action: action ?? this.action,
        documents: documents ?? this.documents,
        party: party ?? this.party,
        icon: icon ?? this.icon,
      );

  Map<String, Object?> toJson() => {
        'title': title,
        'action': action,
        'documents': documents,
        'party': party.toJson(),
        'icon': icon,
      };

  /// Build a [ProcedureStep] from untrusted decoded JSON, defaulting every
  /// missing or malformed field rather than throwing.
  factory ProcedureStep.fromJson(Object? json) {
    final map = JsonReader.asMap(json);
    return ProcedureStep(
      title: JsonReader.asString(map['title']),
      action: JsonReader.asString(map['action']),
      documents: JsonReader.asString(map['documents']),
      party: Party.fromJson(map['party']),
      icon: JsonReader.asString(map['icon']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProcedureStep &&
      other.title == title &&
      other.action == action &&
      other.documents == documents &&
      other.party == party &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(title, action, documents, party, icon);

  @override
  String toString() => 'ProcedureStep($title, party: ${party.name})';
}
