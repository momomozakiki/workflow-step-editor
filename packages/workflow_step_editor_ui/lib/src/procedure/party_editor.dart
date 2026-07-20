import 'package:flutter/material.dart';
import 'package:workflow_step_editor_core/workflow_step_editor_core.dart';

/// Modal editor for a step's [Party]: pick an existing palette entry, or edit a
/// name + colors with an in-house color picker (preset swatches + hex input) —
/// no third-party color-picker dependency. Returns the chosen [Party] plus
/// whether it should be added to the reusable palette.
///
/// Returns `null` if the user cancels.
Future<PartyEditResult?> showPartyEditor(
  BuildContext context, {
  required Party initial,
  required List<Party> palette,
}) {
  return showDialog<PartyEditResult>(
    context: context,
    builder: (_) => _PartyEditorDialog(initial: initial, palette: palette),
  );
}

/// The outcome of [showPartyEditor].
class PartyEditResult {
  const PartyEditResult(this.party, {this.addToPalette = false});

  final Party party;
  final bool addToPalette;
}

class _PartyEditorDialog extends StatefulWidget {
  const _PartyEditorDialog({required this.initial, required this.palette});

  final Party initial;
  final List<Party> palette;

  @override
  State<_PartyEditorDialog> createState() => _PartyEditorDialogState();
}

class _PartyEditorDialogState extends State<_PartyEditorDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial.name);
  late int _background = widget.initial.backgroundArgb;
  late int _text = widget.initial.textArgb;
  bool _addToPalette = false;

  // A neutral swatch grid for quick color choices (ARGB, fully opaque).
  static const List<int> _swatches = [
    0xFFD4E2FF, 0xFF003D8C, 0xFFDDF0E6, 0xFF006B3E,
    0xFFFFF0D6, 0xFF8A5A00, 0xFFE8E0F5, 0xFF4A2D7A,
    0xFFEEF3FA, 0xFF1F4870, 0xFFFFE3E3, 0xFFA94442,
    0xFFFFFFFF, 0xFF000000,
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _applyPreset(Party p) => setState(() {
        _name.text = p.name;
        _background = p.backgroundArgb;
        _text = p.textArgb;
      });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Party'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.palette.isNotEmpty) ...[
                const Text('Reuse', style: _labelStyle),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in widget.palette)
                      ActionChip(
                        label: Text(p.name),
                        backgroundColor: Color(p.backgroundArgb),
                        labelStyle: TextStyle(
                          color: Color(p.textArgb),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        onPressed: () => _applyPreset(p),
                      ),
                  ],
                ),
                const Divider(height: 24),
              ],
              const Text('Name', style: _labelStyle),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _ColorRow(
                label: 'Background',
                selected: _background,
                swatches: _swatches,
                onSelected: (c) => setState(() => _background = c),
              ),
              const SizedBox(height: 12),
              _ColorRow(
                label: 'Text',
                selected: _text,
                swatches: _swatches,
                onSelected: (c) => setState(() => _text = c),
              ),
              const SizedBox(height: 18),
              const Text('Preview', style: _labelStyle),
              const SizedBox(height: 6),
              _badgePreview(),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: _addToPalette,
                onChanged: (v) => setState(() => _addToPalette = v ?? false),
                title: const Text('Add to palette (reuse later)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final party = Party(
              name: _name.text.trim().isEmpty ? 'PARTY' : _name.text.trim(),
              backgroundArgb: _background,
              textArgb: _text,
            );
            Navigator.of(context)
                .pop(PartyEditResult(party, addToPalette: _addToPalette));
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _badgePreview() {
    final name = _name.text.trim().isEmpty ? 'PARTY' : _name.text.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Color(_background),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: Color(_text),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

const TextStyle _labelStyle =
    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6A8BB0));

/// A labelled row of color swatches plus a hex field, sharing one [selected]
/// ARGB value.
class _ColorRow extends StatefulWidget {
  const _ColorRow({
    required this.label,
    required this.selected,
    required this.swatches,
    required this.onSelected,
  });

  final String label;
  final int selected;
  final List<int> swatches;
  final ValueChanged<int> onSelected;

  @override
  State<_ColorRow> createState() => _ColorRowState();
}

class _ColorRowState extends State<_ColorRow> {
  late final TextEditingController _hex =
      TextEditingController(text: _toHex(widget.selected));

  static String _toHex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  void didUpdateWidget(_ColorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final want = _toHex(widget.selected);
    if (_hex.text.toUpperCase() != want) _hex.text = want;
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _applyHex(String value) {
    final parsed = int.tryParse(value.trim().replaceFirst('#', ''), radix: 16);
    if (parsed != null) widget.onSelected(0xFF000000 | (parsed & 0xFFFFFF));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: _labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in widget.swatches)
              GestureDetector(
                onTap: () => widget.onSelected(c),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Color(c),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: c == widget.selected
                          ? const Color(0xFF0A2F5E)
                          : const Color(0x33000000),
                      width: c == widget.selected ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _hex,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixText: '',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onSubmitted: _applyHex,
                onChanged: _applyHex,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
