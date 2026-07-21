import 'package:flutter/widgets.dart';

/// One selectable icon: its stable [key] (stored on `ProcedureStep.icon` and in
/// JSON) and a human [label] shown in the picker and used as the search target.
///
/// The glyph itself is a bundled flat-colour **Twemoji** PNG asset, resolved by
/// [iconAssetFor] / [stepIcon]. The key stays a plain string so the pure-Dart
/// core never sees a Flutter type (same discipline as `Party`'s ARGB ints).
class StepIconOption {
  const StepIconOption(this.key, this.label);

  final String key;
  final String label;
}

/// The curated catalog of step icons.
///
/// Keys are stable and are persisted in the document / JSON — renaming one would
/// orphan every saved step that used it, so add new keys rather than rename. Each
/// key has a matching `assets/icons/twemoji/<key>.png` bundled by this package.
const List<StepIconOption> stepIconCatalog = [
  StepIconOption('assignment', 'Order / assignment'),
  StepIconOption('description', 'Document'),
  StepIconOption('edit_document', 'Draft document'),
  StepIconOption('fact_check', 'Review / check'),
  StepIconOption('checklist', 'Checklist'),
  StepIconOption('handshake', 'Agreement'),
  StepIconOption('gavel', 'Legal / contract'),
  StepIconOption('verified', 'Signed / verified'),
  StepIconOption('gpp_good', 'Approved'),
  StepIconOption('account_balance', 'Bank'),
  StepIconOption('payments', 'Payment'),
  StepIconOption('paid', 'Paid / commission'),
  StepIconOption('request_quote', 'Invoice / quote'),
  StepIconOption('receipt_long', 'Receipt'),
  StepIconOption('science', 'Lab / inspection'),
  StepIconOption('water_drop', 'Sample / dip test'),
  StepIconOption('local_gas_station', 'Fuel / product'),
  StepIconOption('folder', 'Documents folder'),
  StepIconOption('inventory_2', 'Cargo / stock'),
  StepIconOption('warehouse', 'Storage tank'),
  StepIconOption('local_shipping', 'Loading / transport'),
  StepIconOption('directions_boat', 'Vessel'),
  StepIconOption('sailing', 'Shipment'),
  StepIconOption('groups', 'Both parties'),
  StepIconOption('event', 'Schedule'),
  StepIconOption('calendar_month', 'Long-term'),
  StepIconOption('swap_horiz', 'Transfer'),
];

/// Package that bundles the PNG assets. Needed both by `Image.asset(package:)`
/// here and by the host app's PDF exporter, which loads the same file through the
/// `packages/<pkg>/...` rootBundle path.
const String iconAssetPackage = 'workflow_step_editor_ui';
const String _assetDir = 'assets/icons/twemoji';

final Set<String> _keys = {for (final o in stepIconCatalog) o.key};

/// The asset path (relative to [iconAssetPackage]) for [key], or `null` when the
/// key is empty or not in the catalog (e.g. malformed JSON, or a removed icon).
String? iconAssetFor(String key) =>
    _keys.contains(key) ? '$_assetDir/$key.png' : null;

/// The rendered glyph for [key] at [size]×[size], or `null` when there is no
/// icon. The single seam both the editor and the picker render through, so the
/// icon set can be swapped in one place.
Widget? stepIcon(String key, {double size = 24}) {
  final asset = iconAssetFor(key);
  if (asset == null) return null;
  return Image.asset(
    asset,
    package: iconAssetPackage,
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
}

/// Pixel size for a document icon-size key (`ProcedureDocument.iconSizes`).
/// Unknown values fall back to the medium size.
double iconSizePx(String size) {
  switch (size) {
    case 'small':
      return 24;
    case 'large':
      return 52;
    case 'medium':
    default:
      return 36;
  }
}
