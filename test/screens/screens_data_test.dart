import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/generic_screen.dart';

const domainOrder = [
  'integration',
  'auth',
  'realtime',
  'data-fetch-cache',
  'data-transform',
  'search-filter',
  'input-form',
  'routing',
  'theme-design',
  'multiplatform',
  'accessibility',
  'settings-persistence',
  'state-management',
  'error-recovery',
  'observability',
  'testing-quality',
  'build-delivery',
  'security-privacy',
];

const templateJaOrder = [
  '一覧',
  '詳細',
  'フォーム',
  '検索',
  'タブ',
  'ボトムナビゲーション',
  'ドロワー',
  'ダイアログ',
  'グリッド',
  '非同期',
  '設定',
];

String stripVariationSelector(String emoji) =>
    emoji.replaceAll('️', '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('screens.json has 198 screens with a consistent use-case skeleton', () async {
    final screens = await ScreensConfig.load();

    expect(screens, hasLength(198));

    final ids = screens.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(198));
    expect(ids.toSet(), equals(Set<int>.from(List.generate(198, (i) => i + 1))));

    final useCaseKeys = screens.map((s) => s.useCaseKey).toList();
    expect(useCaseKeys.toSet(), hasLength(198));

    final emojis = screens.map((s) => s.emoji).toList();
    expect(emojis.toSet(), hasLength(198));

    final strippedEmojis = emojis.map(stripVariationSelector).toList();
    expect(strippedEmojis.toSet(), hasLength(198));

    for (final screen in screens) {
      final domainIndex = (screen.id - 1) % 18;
      final templateIndex = (screen.id - 1) ~/ 18;

      expect(screen.domainKey, domainOrder[domainIndex],
          reason: 'screen ${screen.id} domainKey mismatch');
      expect(screen.templateJa, templateJaOrder[templateIndex],
          reason: 'screen ${screen.id} templateJa mismatch');
      expect(screen.useCaseKey, startsWith('${screen.domainKey}.'),
          reason: 'screen ${screen.id} useCaseKey should be namespaced by domainKey');
      expect(screen.templateOverride, isNull,
          reason: 'screen ${screen.id} templateOverride should stay null in this batch');

      // Pre-existing keys must survive untouched.
      expect(screen.name, isNotEmpty);
      expect(screen.title, isNotEmpty);
      expect(screen.description, isNotEmpty);
      expect(screen.category, isNotEmpty);
      expect(screen.navigationPattern, isNotEmpty);
      expect(screen.apiPattern, isNotEmpty);
      expect(screen.themePattern, isNotEmpty);
      expect(screen.dataPattern, isNotEmpty);
    }

    for (final domainKey in domainOrder) {
      final count = screens.where((s) => s.domainKey == domainKey).length;
      expect(count, 11, reason: 'domain $domainKey should have 11 screens');
    }

    for (final templateJa in templateJaOrder) {
      final count = screens.where((s) => s.templateJa == templateJa).length;
      expect(count, 18, reason: 'template $templateJa should have 18 screens');
    }

    const detailDomains = ['integration', 'auth'];

    final detailScreens =
        screens.where((s) => detailDomains.contains(s.domainKey)).toList();
    expect(detailScreens, hasLength(22));
    expect(detailScreens.every((s) => s.detail != null), isTrue,
        reason: 'all integration and auth screens should have detail');

    for (final domainKey in detailDomains) {
      final domainScreens =
          screens.where((s) => s.domainKey == domainKey).toList();
      expect(domainScreens, hasLength(11));
      expect(domainScreens.every((s) => s.detail != null), isTrue,
          reason: 'all 11 $domainKey screens should have detail');
    }

    final nonDetailScreens =
        screens.where((s) => !detailDomains.contains(s.domainKey)).toList();
    expect(nonDetailScreens, hasLength(198 - 22));
    expect(nonDetailScreens.every((s) => s.detail == null), isTrue,
        reason: 'non-detail-domain screens should not have detail');

    final allDetailCount = screens.where((s) => s.detail != null).length;
    expect(allDetailCount, 22,
        reason: 'total detail count should be 22 (integration 11 + auth 11)');

    for (final screen in detailScreens) {
      final detail = screen.detail!;
      expect(detail.purpose, isNotEmpty,
          reason: 'screen ${screen.id} detail.purpose should not be empty');
      expect(detail.when, isNotEmpty,
          reason: 'screen ${screen.id} detail.when should not be empty');
      expect(detail.pitfall, isNotEmpty,
          reason: 'screen ${screen.id} detail.pitfall should not be empty');
      expect(detail.snippet, isNotEmpty,
          reason: 'screen ${screen.id} detail.snippet should not be empty');
      expect(detail.points, hasLength(3),
          reason: 'screen ${screen.id} detail.points should have 3 items');
      expect(detail.points.every((p) => p.isNotEmpty), isTrue,
          reason: 'screen ${screen.id} detail.points should not contain empty strings');
    }
  });
}
