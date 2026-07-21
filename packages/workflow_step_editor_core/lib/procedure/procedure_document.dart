/// A whole procedure: an editable [title]/[subtitle] header, an ordered list of
/// [steps], the reusable [parties] palette, plus editable [notes] and [footer]
/// blocks.
///
/// Pure-Dart, immutable, and the unit of JSON (de)serialization for import /
/// export. [fromJson] treats its input as untrusted and never throws on
/// malformed data (see the `wse-input-hardening` skill).
library;

import 'json_read.dart';
import 'party.dart';
import 'procedure_step.dart';

/// Immutable procedure document.
final class ProcedureDocument {
  const ProcedureDocument({
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.parties,
    required this.notes,
    required this.footer,
    this.iconSize = defaultIconSize,
  });

  /// Icon-size key applied to every step's icon; the UI/PDF map it to pixels.
  /// Kept a plain string (not a Flutter size) so the core stays Flutter-free.
  static const String defaultIconSize = 'medium';

  /// The allowed [iconSize] values, smallest to largest.
  static const List<String> iconSizes = ['small', 'medium', 'large'];

  final String title;
  final String subtitle;
  final List<ProcedureStep> steps;

  /// The reusable palette of parties for this document (the "add new party"
  /// list). Saved with the document so it round-trips through JSON.
  final List<Party> parties;

  /// Free-form Key Notes block (one note per line).
  final String notes;

  /// Footer disclaimer line.
  final String footer;

  /// One of [iconSizes]; controls the on-screen and exported step-icon size.
  final String iconSize;

  ProcedureDocument copyWith({
    String? title,
    String? subtitle,
    List<ProcedureStep>? steps,
    List<Party>? parties,
    String? notes,
    String? footer,
    String? iconSize,
  }) =>
      ProcedureDocument(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        steps: steps ?? this.steps,
        parties: parties ?? this.parties,
        notes: notes ?? this.notes,
        footer: footer ?? this.footer,
        iconSize: iconSize ?? this.iconSize,
      );

  Map<String, Object?> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'steps': [for (final s in steps) s.toJson()],
        'parties': [for (final p in parties) p.toJson()],
        'notes': notes,
        'footer': footer,
        'iconSize': iconSize,
      };

  /// Build a [ProcedureDocument] from untrusted decoded JSON. Missing or
  /// malformed fields fall back to the empty/default value; a non-list `steps`
  /// or `parties` yields an empty list rather than an error. Never throws on
  /// shape mismatch.
  factory ProcedureDocument.fromJson(Object? json) {
    final map = JsonReader.asMap(json);
    final parties = [
      for (final p in JsonReader.asList(map['parties'])) Party.fromJson(p),
    ];
    return ProcedureDocument(
      title: JsonReader.asString(map['title']),
      subtitle: JsonReader.asString(map['subtitle']),
      steps: [
        for (final s in JsonReader.asList(map['steps'])) ProcedureStep.fromJson(s),
      ],
      parties: parties.isEmpty ? Party.presets : parties,
      notes: JsonReader.asString(map['notes']),
      footer: JsonReader.asString(map['footer']),
      iconSize: _validIconSize(
        JsonReader.asString(map['iconSize'], fallback: defaultIconSize),
      ),
    );
  }

  /// Clamp an untrusted icon-size value to a known one, defaulting otherwise.
  static String _validIconSize(String value) =>
      iconSizes.contains(value) ? value : defaultIconSize;

  /// The sample "FOB Tank to Vessel (TTV)" procedure ported from the source
  /// HTML — used as the initial document and by "Reset".
  factory ProcedureDocument.defaultTemplate() => const ProcedureDocument(
        title: 'FOB TANK TO VESSEL (TTV)',
        subtitle: 'Trial Shipment - MT799 RWA & SGS Dip Test',
        parties: Party.presets,
        steps: [
          ProcedureStep(
            title: 'ICPO & DOCUMENTS',
            action:
                'Buyer issues Irrevocable Corporate Purchase Order (ICPO), '
                'Charter Party Agreement (CPA), Vessel Q88, and accepts the '
                "Seller's working procedure.",
            documents: 'ICPO, CPA, Vessel Q88',
            party: Party.buyer,
            icon: 'assignment',
          ),
          ProcedureStep(
            title: 'CI & DRAFT SPA',
            action:
                'Seller issues Commercial Invoice (CI) and Draft Sales and '
                'Purchase Agreement (SPA).',
            documents: 'Commercial Invoice (CI), Draft SPA',
            party: Party.seller,
            icon: 'handshake',
          ),
          ProcedureStep(
            title: 'SIGN & RETURN',
            action:
                'Buyer signs, seals, and returns the CI and Draft SPA to the '
                'Seller.',
            documents: 'Signed CI, Signed SPA',
            party: Party.buyer,
            icon: 'verified',
          ),
          ProcedureStep(
            title: 'MT799 RWA',
            action:
                'Buyer instructs its bank to issue operative SWIFT MT799 RWA to '
                "Seller's nominated bank as Proof of Funds.",
            documents: 'SWIFT MT799 RWA',
            party: Party.buyer,
            icon: 'account_balance',
          ),
          ProcedureStep(
            title: 'RELEASE OF POP',
            action:
                'Upon authentication of MT799 RWA, Seller releases POP: TSR, '
                'Fresh SGS Report, ATV, UDTA. Buyer verifies within 3 banking '
                'days.',
            documents: 'TSR, SGS Report, ATV, UDTA, COO, ATSC',
            party: Party.seller,
            icon: 'folder',
          ),
          ProcedureStep(
            title: 'SGS DIP TEST',
            action:
                "Buyer appoints independent SGS Inspector, at Buyer's expense, "
                'to conduct Dip Test, Quantity & Quality Inspection within 3 '
                'banking days after POP verification.',
            documents: 'SGS Dip Test Report',
            party: Party.buyer,
            icon: 'science',
          ),
          ProcedureStep(
            title: 'COMMENCEMENT OF LOADING',
            action:
                'Upon successful SGS Dip Test, Terminal Operator commences '
                "loading/injection from Seller's storage tank into Buyer's "
                'nominated vessel.',
            documents: 'Loading Plan, Injection Report',
            party: Party.terminalOperator,
            icon: 'local_shipping',
          ),
          ProcedureStep(
            title: 'PAYMENT (MT103)',
            action:
                'Buyer shall remit 100% payment by SWIFT MT103 within 24 '
                'banking hours after completion of loading and issuance of B/L.',
            documents: 'Bill of Lading (B/L), SWIFT MT103',
            party: Party.buyer,
            icon: 'payments',
          ),
          ProcedureStep(
            title: 'TITLE TRANSFER & DOCS',
            action:
                'Upon confirmation of full payment, Seller transfers legal '
                'title, ownership, risk, and all original shipping & commercial '
                'documents to Buyer.',
            documents: 'Original Shipping Documents, Commercial Documents',
            party: Party.seller,
            icon: 'description',
          ),
          ProcedureStep(
            title: 'COMMISSION PAYMENT',
            action:
                'Seller shall pay all commissions to intermediaries in '
                'accordance with the executed NCDNA/IMFPA.',
            documents: 'NCDNA / IMFPA',
            party: Party.seller,
            icon: 'paid',
          ),
          ProcedureStep(
            title: 'LONG-TERM CONTRACT',
            action:
                'Upon successful Trial Shipment, both Parties enter 12-Month '
                'FOB SPA. Payment: operative MT760 SBLC as guarantee, followed '
                'by MT103 per shipment.',
            documents: 'Operative SBLC MT760, SWIFT MT103',
            party: Party.both,
            icon: 'calendar_month',
          ),
        ],
        notes:
            "MT799 RWA ensures Buyer's financial ability before POP is "
            'released.\n'
            'SGS Dip Test is conducted before payment to ensure quality & '
            'quantity.\n'
            "Loading is performed by Terminal Operator from Seller's tank "
            "to Buyer's vessel.\n"
            'MT103 payment is made after loading completion and B/L issuance.\n'
            'This procedure ensures transparency, security and fair protection '
            'for both Parties.',
        footer:
            'ALL STEPS SHALL BE SUBJECT TO THE TERMS AND CONDITIONS SET FORTH '
            'IN THE SPA.',
      );

  @override
  String toString() =>
      'ProcedureDocument($title, ${steps.length} steps, '
      '${parties.length} parties)';
}
