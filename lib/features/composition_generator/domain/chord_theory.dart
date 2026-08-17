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

  static int pitchClass(String note) {
    const values = <String, int>{
      'C': 0,
      'B♯': 0,
      'C♯': 1,
      'D♭': 1,
      'D': 2,
      'D♯': 3,
      'E♭': 3,
      'E': 4,
      'F♭': 4,
      'E♯': 5,
      'F': 5,
      'F♯': 6,
      'G♭': 6,
      'G': 7,
      'G♯': 8,
      'A♭': 8,
      'A': 9,
      'A♯': 10,
      'B♭': 10,
      'B': 11,
      'C♭': 11,
    };
    final value = values[note];
    if (value == null) throw ArgumentError.value(note, 'note', 'Unsupported note');
    return value;
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

  static List<String> scale(String key, {required bool minor}) {
    final root = pitchClass(key);
    final intervals = minor ? minorIntervals : majorIntervals;
    final sharps = prefersSharps(key);
    return [
      for (final interval in intervals)
        noteForPitchClass(root + interval, sharps: sharps),
    ];
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
    final normalized = token
        .replaceAll('♭', '')
        .replaceAll('♯', '')
        .replaceAll(RegExp(r'[^ivIV]'), '')
        .toUpperCase();
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
    final degree = romanDegree(token);
    if (degree == null) return token;
    return diatonicChord(key, degree, minor: minor);
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
}
