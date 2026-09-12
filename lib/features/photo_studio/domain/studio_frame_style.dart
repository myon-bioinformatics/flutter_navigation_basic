/// Frame shape drawn inside a normalized bounding box.
enum StudioFrameShape {
  rectangle,
  circle,
  triangle,
}

/// Preset stroke colors for the studio frame (ARGB).
class StudioFrameColors {
  const StudioFrameColors._();

  static const int purple = 0xFF7E57C2;
  static const int red = 0xFFE53935;
  static const int green = 0xFF43A047;
  static const int blue = 0xFF1E88E5;
  static const int amber = 0xFFFDD835;
  static const int white = 0xFFFFFFFF;
  static const int black = 0xFF212121;

  static const List<int> presets = <int>[
    purple,
    red,
    green,
    blue,
    amber,
    white,
    black,
  ];
}
