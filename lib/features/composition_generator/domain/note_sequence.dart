class NoteSequence {
  NoteSequence._();

  static final RegExp _notePattern = RegExp(r'^([A-Ga-g])([#b♯♭]?)(-?\d)$');

  static List<String> parse(String input) {
    return input
        .replaceAll(',', ' ')
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map(normalizeNote)
        .toList(growable: false);
  }

  static String normalizeNote(String token) {
    final match = _notePattern.firstMatch(token);
    if (match == null) {
      throw FormatException('Invalid note: $token');
    }
    final letter = match.group(1)!.toUpperCase();
    final accidental = switch (match.group(2)) {
      '#' => '♯',
      'b' => '♭',
      final value => value ?? '',
    };
    return '$letter$accidental${match.group(3)}';
  }

  static int notesPerBar({
    required int beatsPerBar,
    required int beatUnit,
    required int noteUnit,
  }) {
    if (noteUnit != 4 && noteUnit != 8) {
      throw ArgumentError.value(noteUnit, 'noteUnit', 'Only quarter/eighth notes are supported');
    }
    final value = beatsPerBar * noteUnit / beatUnit;
    if (value != value.roundToDouble()) {
      throw ArgumentError('The selected note value does not divide this bar evenly');
    }
    return value.round();
  }

  static List<List<String>> bars(
    List<String> notes, {
    required int beatsPerBar,
    required int beatUnit,
    required int noteUnit,
  }) {
    final capacity = notesPerBar(
      beatsPerBar: beatsPerBar,
      beatUnit: beatUnit,
      noteUnit: noteUnit,
    );
    if (notes.isEmpty) return const [];
    return [
      for (var start = 0; start < notes.length; start += capacity)
        notes.sublist(start, (start + capacity).clamp(0, notes.length)),
    ];
  }
}
