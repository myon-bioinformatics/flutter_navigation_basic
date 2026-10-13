import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Read-only image surface shared by Photo Studio and image attachments.
///
/// The parent owns sizing, clipping, and any editing overlay. Keeping the
/// fit, backdrop, and playback settings here avoids divergent previews.
class StudioImagePreview extends StatelessWidget {
  const StudioImagePreview({
    super.key,
    required this.bytes,
    this.errorBuilder,
  });

  final Uint8List bytes;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: errorBuilder,
      ),
    );
  }
}
