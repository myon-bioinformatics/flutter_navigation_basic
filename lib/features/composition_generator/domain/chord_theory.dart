class ChordTheory {
  ChordTheory._();

  static const List<String> flatKeys = [
    'C', 'D♭', 'D', 'E♭', 'E', 'F', 'G♭', 'G', 'A♭', 'A', 'B♭', 'B',
  ];

  static const List<String> sharpKeys = [
    'C', 'C♯', 'D', 'D♯', 'E', 'F', 'F♯', 'G', 'G♯', 'A', 'A♯', 'B',
  ];

  static const List<String> selectableKeys = [
    'C',
    'C♯',
    'D♭',
    'D',
    'D♯',
    'E♭',
    'E',
    'F',
    'F♯',
    'G♭',
    'G',
    'G♯',
    'A♭',
    'A',
    'A♯',
    'B♭',
    'B',
  ];

  static const List<int> majorIntervals = [0, 2, 4, 5, 7, 9, 11];
  static const List<int> minorIntervals = [0, 2, 3, 5, 7, 8, 10];

  static const List<String> majorDegreeQualities = ['', 'm', 'm', '', '', 'm', 'dim'];
  static const List<String> minorDegreeQualities = ['m', 'dim', '', 'm', 'm', '', ''];

  static const List<String> chordModifiers = [
    'triad',
    '6',
    'm6',
    '7',
    'maj7',
    'm7',
    'm7♭5',
    'sus2',
    'sus4',
    'add9',
    'add11',
    'dim',
    'aug',
  ];

  static const List<String> _letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const Map<String, int> _naturalPitchClasses = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  static int pitchClass(String note) {
    final match = RegExp(r'^([A-G])([♯♭]*)$').firstMatch(note);
    if (match == null) {
      throw ArgumentError.value(note, 'note', 'Unsupported note');
    }
    var value = _naturalPitchClasses[match.group(1)!]!;
    for (final rune in match.group(2)!.runes) {
      final accidental = String.fromCharCode(rune);
      if (accidental == '♯') value += 1;
      if (accidental == '♭') value -= 1;
    }
    return ((value % 12) + 12) % 12;
  }

  static bool prefersSharps(String key) =>
      key.contains('♯') || const {'D', 'E', 'G', 'A', 'B'}.contains(key);

  static String noteForPitchClass(int pitchClass, {required bool sharps}) {
    final list = sharps ? sharpKeys : flatKeys;
    final normalized = ((pitchClass % 12) + 12) % 12;
    return list[normalized];
  }

  static String transposeKey(String key, int semitones) {
    final root = pitchClass(key);
    return noteForPitchClass(
      root + semitones,
      sharps: prefersSharps(key),
    );
  }

  static String fifthNeighbor(String key, {required bool clockwise}) {
    return transposeKey(key, clockwise ? 7 : -7);
  }

  static List<String> scale(String key, {required bool minor}) {
    final rootPitch = pitchClass(key);
    final rootLetter = key.substring(0, 1);
    final rootLetterIndex = _letters.indexOf(rootLetter);
    if (rootLetterIndex < 0) {
      throw ArgumentError.value(key, 'key', 'Unsupported root letter');
    }

    final intervals = minor ? minorIntervals : majorIntervals;
    return [
      for (var degree = 0; degree < 7; degree++)
        _spellPitch(
          letter: _letters[(rootLetterIndex + degree) % 7],
          pitchClass: rootPitch + intervals[degree],
        ),
    ];
  }

  static String _spellPitch({required String letter, required int pitchClass}) {
    final target = ((pitchClass % 12) + 12) % 12;
    final natural = _naturalPitchClasses[letter]!;
    var delta = target - natural;
    if (delta > 6) delta -= 12;
    if (delta < -6) delta += 12;

    final accidental = switch (delta) {
      -2 => '♭♭',
      -1 => '♭',
      0 => '',
      1 => '♯',
      2 => '♯♯',
      _ => throw StateError('Cannot spell pitch $target on letter $letter'),
    };
    return '$letter$accidental';
  }

  static String diatonicChord(String key, int degree, {required bool minor}) {
    if (degree < 1 || degree > 7) {
      throw ArgumentError.value(degree, 'degree', 'Expected 1 through 7');
    }
    final notes = scale(key, minor: minor);
    final qualities = minor ? minorDegreeQualities : majorDegreeQualities;
    return '${notes[degree - 1]}${qualities[degree - 1]}';
  }

  static int? romanDegree(String token) {
    final match = RegExp(r'^([ivIV]+)').firstMatch(token.trim());
    if (match == null) return null;
    final normalized = match.group(1)!.toUpperCase();
    const degrees = <String, int>{
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
    };
    return degrees[normalized];
  }

  static String convertRomanToken(String key, String token, {required bool minor}) {
    final trimmed = token.trim();
    final match = RegExp(r'^([ivIV]+)(.*)$').firstMatch(trimmed);
    if (match == null) return token;

    final degree = romanDegree(trimmed);
    if (degree == null) return token;

    final root = scale(key, minor: minor)[degree - 1];
    final baseChord = diatonicChord(key, degree, minor: minor);
    final suffix = match.group(2)!.trim();
    if (suffix.isEmpty) return baseChord;

    switch (suffix) {
      case '6':
        return '$baseChord6';
      case 'm6':
        return '${root}m6';
      case '7':
        return '$baseChord7';
      case 'maj7':
      case 'M7':
      case '△7':
        return '${root}maj7';
      case 'm7':
        return '${root}m7';
      case 'm7♭5':
      case 'ø7':
        return '${root}m7♭5';
      case 'sus2':
      case 'sus4':
      case 'add9':
      case 'add11':
        return '$root$suffix';
      case 'dim':
      case '°':
        return '${root}dim';
      case 'aug':
      case '+':
        return '${root}aug';
      default:
        return baseChord;
    }
  }

  static List<String> convertProgression(
    String key,
    String progression, {
    required bool minor,
  }) {
    final tokens = progression
        .replaceAll('–', ' ')
        .replaceAll('—', ' ')
        .replaceAll('-', ' ')
        .replaceAll('|', ' ')
        .split(RegExp(r'[\s,]+'))
        .where((value) => value.isNotEmpty);
    return [
      for (final token in tokens)
        convertRomanToken(key, token, minor: minor),
    ];
  }

  static String applyModifier(String root, String modifier) {
    switch (modifier) {
      case 'triad':
        return root;
      case '6':
      case 'm6':
      case '7':
      case 'maj7':
      case 'm7':
      case 'm7♭5':
      case 'sus2':
      case 'sus4':
      case 'add9':
      case 'add11':
      case 'dim':
      case 'aug':
        return '$root$modifier';
    }
    throw ArgumentError.value(
      modifier,
      'modifier',
      'Unsupported chord modifier',
    );
  }

  static List<int> chordIntervals(String modifier) {
    return switch (modifier) {
      'triad' => const [0, 4, 7],
      '6' => const [0, 4, 7, 9],
      'm6' => const [0, 3, 7, 9],
      '7' => const [0, 4, 7, 10],
      'maj7' => const [0, 4, 7, 11],
      'm7' => const [0, 3, 7, 10],
      'm7♭5' => const [0, 3, 6, 10],
      'sus2' => const [0, 2, 7],
      'sus4' => const [0, 5, 7],
      'add9' => const [0, 4, 7, 14],
      'add11' => const [0, 4, 7, 17],
      'dim' => const [0, 3, 6],
      'aug' => const [0, 4, 8],
      _ => throw ArgumentError.value(
          modifier,
          'modifier',
          'Unsupported chord modifier',
        ),
    };
  }

  static List<String> chordTones(String root, String modifier) {
    final rootPitch = pitchClass(root);
    final sharps = prefersSharps(root);
    return [
      for (final interval in chordIntervals(modifier))
        noteForPitchClass(rootPitch + interval, sharps: sharps),
    ];
  }

  static int normalizedInversion(String modifier, int inversion) {
    if (inversion < 0 || inversion > 3) {
      throw ArgumentError.value(inversion, 'inversion', 'Expected 0 through 3');
    }
    final toneCount = chordIntervals(modifier).length;
    if (inversion < toneCount) return inversion;
    // Triads only have root / first / second inversion. For a compact four-state
    // UI, the requested third-inversion slot loops back to first inversion.
    if (toneCount == 3 && inversion == 3) return 1;
    return inversion % toneCount;
  }

  static String chordWithInversion(
    String root,
    String modifier,
    int inversion,
  ) {
    final chord = applyModifier(root, modifier);
    final normalized = normalizedInversion(modifier, inversion);
    if (normalized == 0) return chord;
    final bass = chordTones(root, modifier)[normalized];
    return '$chord/$bass';
  }
}
