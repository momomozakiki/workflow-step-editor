import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Rasterizes a Material [IconData] glyph to transparent-background PNG bytes.
///
/// The PDF exporter embeds these as images rather than an icon *font* because
/// the only Material-icons font Flutter ships offline uses CFF/PostScript
/// outlines (`OTTO`), which the `pdf` package's TrueType parser cannot read.
/// Flutter's own renderer handles that font fine, so we paint the glyph here and
/// hand a PNG to the PDF — keeping icon export fully offline.
///
/// Rendered at [size] device pixels (default 48 for a crisp downscale) in
/// [color]; the PDF scales it down to the ~12pt text height.
Future<Uint8List> rasterizeIcon(
  IconData icon, {
  double size = 48,
  Color color = const Color(0xFF0A2F5E),
}) async {
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Offset.zero);
  final picture = recorder.endRecording();

  final width = painter.width.ceil().clamp(1, 4096);
  final height = painter.height.ceil().clamp(1, 4096);
  final image = await picture.toImage(width, height);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}
