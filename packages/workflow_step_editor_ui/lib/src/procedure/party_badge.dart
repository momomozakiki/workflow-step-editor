import 'package:flutter/material.dart';

import 'party_editor.dart';
import 'procedure_editor_controller.dart';

/// The rounded, colored party badge for one step. Tapping it opens
/// [showPartyEditor] and writes the result back through [controller].
class PartyBadge extends StatelessWidget {
  const PartyBadge({
    super.key,
    required this.controller,
    required this.index,
  });

  final ProcedureEditorController controller;
  final int index;

  Future<void> _edit(BuildContext context) async {
    final step = controller.document.steps[index];
    final result = await showPartyEditor(
      context,
      initial: step.party,
      palette: controller.parties,
    );
    if (result == null) return;
    controller.updateParty(index, result.party);
    if (result.addToPalette) controller.addPartyToPalette(result.party);
  }

  @override
  Widget build(BuildContext context) {
    final party = controller.document.steps[index].party;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => _edit(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Color(party.backgroundArgb),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Text(
          party.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(party.textArgb),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
