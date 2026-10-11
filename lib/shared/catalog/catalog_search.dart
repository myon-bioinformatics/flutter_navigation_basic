import '../screens/generic_screen.dart';

/// One catalog search contract shared by Hub and Screen6.
///
/// Match actual use-case/domain information, not just the generic category
/// and placeholder tags. Preserve the source ordering for stable navigation.
List<ScreenData> searchCatalog(List<ScreenData> screens, String input) {
  final query = input.trim().toLowerCase();
  if (query.isEmpty) return List<ScreenData>.of(screens);
  return screens.where((screen) {
    final values = <String>[
      screen.screenDataId.toString(),
      'screen${screen.screenDataId}',
      screen.name,
      screen.title,
      screen.description,
      screen.category,
      screen.domainKey,
      screen.domainJa,
      screen.useCaseJa,
      screen.useCaseEn,
      screen.useCaseKey,
    ];
    return values.any((value) => value.toLowerCase().contains(query));
  }).toList();
}
