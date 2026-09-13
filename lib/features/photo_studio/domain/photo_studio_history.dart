import 'photo_studio_state.dart';

/// Bounded undo stack for [PhotoStudioState].
///
/// Pure Dart (no Flutter imports). Stores states as-is so [Uint8List]
/// image payloads stay shared by reference across history entries.
class PhotoStudioHistory {
  PhotoStudioHistory({this.maxEntries = 20});

  final int maxEntries;

  final List<PhotoStudioState> _entries = <PhotoStudioState>[];
  PhotoStudioState? _pending;

  int get depth => _entries.length;

  bool get canUndo => _entries.isNotEmpty;

  /// Starts a gesture transaction if one is not already open.
  void beginGesture(PhotoStudioState current) {
    _pending ??= current;
  }

  /// Ends a gesture: commits [pending] when [current] differs; discards no-ops.
  ///
  /// Returns whether an entry was committed.
  bool endGesture(PhotoStudioState current) {
    final pending = _pending;
    _pending = null;
    if (pending == null) return false;
    if (pending == current) return false;
    _push(pending);
    return true;
  }

  /// Records [before] when it differs from [after]. Returns whether committed.
  bool recordChange(PhotoStudioState before, PhotoStudioState after) {
    if (before == after) return false;
    _push(before);
    return true;
  }

  /// Pops the latest entry, clears any pending gesture, or returns null.
  PhotoStudioState? undo() {
    _pending = null;
    if (_entries.isEmpty) return null;
    return _entries.removeLast();
  }

  void clearPending() {
    _pending = null;
  }

  void _push(PhotoStudioState state) {
    _entries.add(state);
    if (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }
}
