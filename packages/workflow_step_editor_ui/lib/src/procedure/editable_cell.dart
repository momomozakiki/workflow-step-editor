import 'package:flutter/material.dart';

/// A single editable text cell (procedure title / action / documents).
///
/// Backed by a [TextField]; plain text for now, kept deliberately thin so a
/// later `RichText`/`TextSpan` variant (inline icons/images) can replace it
/// without touching callers. Holds its own [TextEditingController] so typing
/// does not fight the parent's rebuilds — the controller's text is only reset
/// from [value] when they genuinely diverge (e.g. after Reset/Import).
class EditableCell extends StatefulWidget {
  const EditableCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.bold = false,
    this.maxLines,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool bold;
  final int? maxLines;

  @override
  State<EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<EditableCell> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(EditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      minLines: 1,
      style: TextStyle(
        fontSize: 13,
        fontWeight: widget.bold ? FontWeight.w700 : FontWeight.w400,
        color: const Color(0xFF1A2A3A),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Color(0xFFA8B8CE), fontSize: 12),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
