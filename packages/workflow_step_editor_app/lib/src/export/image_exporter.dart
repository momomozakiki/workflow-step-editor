import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captures a widget subtree (the procedure card) to a PNG and saves it via a
/// native dialog. A platform concretion — kept in the host app.
class ImageExporter {
  const ImageExporter();

  static const XTypeGroup _group = XTypeGroup(
    label: 'PNG',
    extensions: <String>['png'],
  );

  /// Rasterize the [RepaintBoundary] behind [boundaryKey] to PNG bytes at
  /// [pixelRatio]. Returns `null` if the boundary is not mounted.
  Future<Uint8List?> capture(
    GlobalKey boundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    final object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;
    final image = await object.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Prompt for a destination and write [bytes]. Returns the path, or `null` if
  /// the user cancels.
  Future<String?> savePng(
    Uint8List bytes, {
    String suggestedName = 'procedure.png',
  }) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [_group],
      suggestedName: suggestedName,
    );
    if (location == null) return null;
    await File(location.path).writeAsBytes(bytes);
    return location.path;
  }
}
