/// High-level canvas interaction mode for Photo Studio (mockup-aligned).
///
/// Keeps create / stamp / move / resize as explicit modes without a larger
/// scaffold abstraction.
enum StudioCanvasMode {
  /// Drag empty space to create a frame (uses [PhotoRectCanvas.draftShape]).
  frame,

  /// Place or drag stamps.
  stamp,

  /// Move selected frames / stamps (no create, no resize handles).
  move,

  /// Resize via handles only (no create, no body-drag move).
  resize,
}
