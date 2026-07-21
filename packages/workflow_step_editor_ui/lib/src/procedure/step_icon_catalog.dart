import 'package:flutter/material.dart';

/// One selectable icon: its stable [key] (stored on `ProcedureStep.icon` and in
/// JSON), the concrete [icon] glyph, and a human [label] shown in the picker and
/// used as the search target.
class StepIconOption {
  const StepIconOption(this.key, this.icon, this.label);

  final String key;
  final IconData icon;
  final String label;
}

/// The curated catalog of step icons.
///
/// This is the single source of truth mapping a stored [StepIconOption.key] to a
/// Flutter [IconData]. The PDF exporter reads `IconData.codePoint` from the same
/// table (via [iconFor]) so the editor, PNG, and PDF never drift.
///
/// Every entry is a `const Icons.*` literal on purpose: Flutter's release-build
/// icon tree-shaker only keeps glyphs referenced by const [IconData]s, so this
/// keeps the icons from being stripped without needing `--no-tree-shake-icons`.
const List<StepIconOption> stepIconCatalog = [
  StepIconOption('assignment', Icons.assignment, 'Order / assignment'),
  StepIconOption('description', Icons.description, 'Document'),
  StepIconOption('edit_document', Icons.edit_document, 'Draft document'),
  StepIconOption('fact_check', Icons.fact_check, 'Review / check'),
  StepIconOption('checklist', Icons.checklist, 'Checklist'),
  StepIconOption('handshake', Icons.handshake, 'Agreement'),
  StepIconOption('gavel', Icons.gavel, 'Legal / contract'),
  StepIconOption('verified', Icons.verified, 'Signed / verified'),
  StepIconOption('gpp_good', Icons.gpp_good, 'Approved'),
  StepIconOption('account_balance', Icons.account_balance, 'Bank'),
  StepIconOption('payments', Icons.payments, 'Payment'),
  StepIconOption('paid', Icons.paid, 'Paid / commission'),
  StepIconOption('request_quote', Icons.request_quote, 'Invoice / quote'),
  StepIconOption('receipt_long', Icons.receipt_long, 'Receipt'),
  StepIconOption('science', Icons.science, 'Lab / inspection'),
  StepIconOption('water_drop', Icons.water_drop, 'Sample / dip test'),
  StepIconOption('local_gas_station', Icons.local_gas_station, 'Fuel / product'),
  StepIconOption('folder', Icons.folder, 'Documents folder'),
  StepIconOption('inventory_2', Icons.inventory_2, 'Cargo / stock'),
  StepIconOption('warehouse', Icons.warehouse, 'Storage tank'),
  StepIconOption('local_shipping', Icons.local_shipping, 'Loading / transport'),
  StepIconOption('directions_boat', Icons.directions_boat, 'Vessel'),
  StepIconOption('sailing', Icons.sailing, 'Shipment'),
  StepIconOption('groups', Icons.groups, 'Both parties'),
  StepIconOption('event', Icons.event, 'Schedule'),
  StepIconOption('calendar_month', Icons.calendar_month, 'Long-term'),
  StepIconOption('swap_horiz', Icons.swap_horiz, 'Transfer'),
];

/// Lookup table keyed by [StepIconOption.key], built once from [stepIconCatalog].
final Map<String, StepIconOption> _byKey = {
  for (final option in stepIconCatalog) option.key: option,
};

/// Resolve a stored [key] to its glyph, or `null` when the key is empty or
/// unknown (e.g. an icon removed from the catalog, or malformed JSON).
IconData? iconFor(String key) => _byKey[key]?.icon;
