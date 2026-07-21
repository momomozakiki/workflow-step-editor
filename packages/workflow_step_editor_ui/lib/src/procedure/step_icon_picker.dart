import 'package:flutter/material.dart';

import 'step_icon_catalog.dart';

const Color _navy = Color(0xFF0A2F5E);
const TextStyle _labelStyle =
    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6A8BB0));

/// Modal picker for a step's icon: search-filter a grid of the [stepIconCatalog]
/// and tap to choose, or clear with "None".
///
/// Returns the chosen [StepIconOption.key], `''` for none, or `null` if the user
/// cancels. Mirrors the `showPartyEditor` dialog conventions.
Future<String?> showStepIconPicker(
  BuildContext context, {
  required String initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _StepIconPickerDialog(initial: initial),
  );
}

class _StepIconPickerDialog extends StatefulWidget {
  const _StepIconPickerDialog({required this.initial});

  final String initial;

  @override
  State<_StepIconPickerDialog> createState() => _StepIconPickerDialogState();
}

class _StepIconPickerDialogState extends State<_StepIconPickerDialog> {
  final TextEditingController _search = TextEditingController();
  late String _selected = widget.initial;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<StepIconOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return stepIconCatalog;
    return [
      for (final o in stepIconCatalog)
        if (o.label.toLowerCase().contains(q) || o.key.contains(q)) o,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return AlertDialog(
      title: const Text('Step icon'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Search icons…',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 6),
            _NoneTile(
              selected: _selected.isEmpty,
              onTap: () => setState(() => _selected = ''),
            ),
            const SizedBox(height: 8),
            const Text('Icons', style: _labelStyle),
            const SizedBox(height: 6),
            SizedBox(
              height: 220,
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No matching icons', style: _labelStyle),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final option in filtered)
                            _IconTile(
                              option: option,
                              selected: option.key == _selected,
                              onTap: () =>
                                  setState(() => _selected = option.key),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// A tappable "no icon" row.
class _NoneTile extends StatelessWidget {
  const _NoneTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _navy : const Color(0x33000000),
            width: selected ? 2 : 1,
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.not_interested, size: 20, color: Color(0xFF6A8BB0)),
            SizedBox(width: 8),
            Text('None', style: _labelStyle),
          ],
        ),
      ),
    );
  }
}

/// A single selectable icon tile (glyph + label) in the grid.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StepIconOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Tooltip(
        message: option.label,
        child: Container(
          width: 84,
          height: 76,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF3FA) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _navy : const Color(0x22000000),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              stepIcon(option.key, size: 28) ??
                  const SizedBox(width: 28, height: 28),
              const SizedBox(height: 4),
              Text(
                option.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6A8BB0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
