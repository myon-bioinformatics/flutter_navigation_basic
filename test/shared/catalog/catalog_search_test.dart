import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_navigation_basic/shared/catalog/catalog_search.dart';
import 'package:flutter_navigation_basic/screens/generic_screen.dart';

void main() {
  final screens = [
    const ScreenData(
      screenDataId: 5, name: 'Screen5', title: 'Result',
      emoji: '🔎', description: 'A sample', category: 'data',
      navigationPattern: '', apiPattern: '', themePattern: '', dataPattern: '',
      domainKey: 'processing', domainJa: '変換',
      useCaseJa: '結果一覧', useCaseEn: 'Transformed Result List',
      useCaseKey: 'transformed_result_list',
    ),
    const ScreenData(
      screenDataId: 6, name: 'Screen6', title: 'Other',
      emoji: '📱', description: 'Unrelated', category: 'navigation',
      navigationPattern: '', apiPattern: '', themePattern: '', dataPattern: '',
    ),
  ];

  test('use-case query selects only matching screen, case insensitive', () {
    final result = searchCatalog(screens, '  TRANSFORMED RESULT LIST  ');
    expect(result.map((s) => s.screenDataId), [5]);
  });

  test('domain and screen ID are searchable', () {
    expect(searchCatalog(screens, '変換').single.screenDataId, 5);
    expect(searchCatalog(screens, 'screen6').single.screenDataId, 6);
  });

  test('no match is empty; clearing restores source order', () {
    expect(searchCatalog(screens, 'no_such_use_case'), isEmpty);
    expect(searchCatalog(screens, ' ').map((s) => s.screenDataId), [5, 6]);
  });
}
