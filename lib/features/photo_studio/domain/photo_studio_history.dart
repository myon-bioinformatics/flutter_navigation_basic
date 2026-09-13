import 'photo_studio_state.dart';

/// Bounded undo/redo stacks for [PhotoStudioState].
///
/// Pure Dart (no Flutter imports). Stores states as-is so [Uint8List]
/// image payloads stay shared by reference across history entries.
class PhotoStudioHistory {
  PhotoStudioHistory({this.maxEntries = 20});

  final int maxEntries;

  final List<PhotoStudioState> _undo = <PhotoStudioState>[];
  final List<PhotoStudioState> _redo = <PhotoStudioState>[];
  PhotoStudioState? _pending;

  int get depth => _undo.length;

  bool get canUndo => _undo.isNotEmpty;

  bool get canRedo => _redo.isNotEmpty;

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
    _pushUndo(pending);
    return true;
  }

  /// Records [before] when it differs from [after]. Returns whether committed.
  bool recordChange(PhotoStudioState before, PhotoStudioState after) {
    if (before == after) return false;
    _pushUndo(before);
    return true;
  }

  /// Pops undo, pushes [current] onto redo, or returns null.
  PhotoStudioState? undo(PhotoStudioState current) {
    _pending = null;
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  /// Pops redo, pushes [current] onto undo, or returns null.
  PhotoStudioState? redo(PhotoStudioState current) {
    _pending = null;
    if (_redo.isEmpty) return null;
    _undo.add(current);
    if (_undo.length > maxEntries) {
      _undo.removeAt(0);
    }
    return _redo.removeLast();
  }

  void clearPending() {
    _pending = null;
  }

  /// Drops undo/redo stacks and any open gesture (e.g. after Discard).
  void clear() {
    _pending = null;
    _undo.clear();
    _redo.clear();
  }

  void _pushUndo(PhotoStudioState state) {
    _undo.add(state);
    if (_undo.length > maxEntries) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }
}
