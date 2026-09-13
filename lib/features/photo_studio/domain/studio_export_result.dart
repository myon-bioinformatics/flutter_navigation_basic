/// Outcome of [exportStudioPng] orchestration (save / platform boundary).
enum StudioExportOutcome {
  saved,
  unavailable,
  failed,
}

/// Structured result from Photo Studio PNG export.
class StudioExportResult {
  const StudioExportResult({
    required this.outcome,
    required this.width,
    required this.height,
    required this.bytesLength,
    required this.elapsedMilliseconds,
  });

  final StudioExportOutcome outcome;
  final int width;
  final int height;
  final int bytesLength;
  final int elapsedMilliseconds;
}
