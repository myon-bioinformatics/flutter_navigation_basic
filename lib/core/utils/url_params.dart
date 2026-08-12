import 'package:get/get.dart';

/// URLパラメータ取得の標準化ユーティリティ
///
/// GetX の [Get.parameters]（パスパラメータ）と [Get.query]（クエリパラメータ）を
/// 型安全・Null安全に取得するためのヘルパークラス。
///
/// ルート定義例:
/// ```
/// GetPage(name: '/user/:id', ...)
/// GetPage(name: '/post/:postId/comment/:commentId', ...)
/// ```
///
/// よくある取得ケース一覧（Case 1〜18）については [UrlParamsCases] を参照。
class UrlParams {
  UrlParams._();

  // ─────────────────────────────────────────────
  // Case 1: パスパラメータを String で取得
  // ルート例: /user/:id → /user/42
  // ─────────────────────────────────────────────
  static String pathString(String key, {String fallback = ''}) {
    return Get.parameters[key] ?? fallback;
  }

  // ─────────────────────────────────────────────
  // Case 2: パスパラメータを int で取得
  // ルート例: /item/:id → /item/10
  // ─────────────────────────────────────────────
  static int pathInt(String key, {int fallback = 0}) {
    return int.tryParse(Get.parameters[key] ?? '') ?? fallback;
  }

  // ─────────────────────────────────────────────
  // Case 3: パスパラメータを double で取得
  // ルート例: /price/:amount → /price/3.14
  // ─────────────────────────────────────────────
  static double pathDouble(String key, {double fallback = 0.0}) {
    return double.tryParse(Get.parameters[key] ?? '') ?? fallback;
  }

  // ─────────────────────────────────────────────
  // Case 4: パスパラメータを bool で取得
  // ルート例: /feature/:enabled → /feature/true
  // ─────────────────────────────────────────────
  static bool pathBool(String key, {bool fallback = false}) {
    final raw = Get.parameters[key];
    if (raw == null) return fallback;
    return raw.toLowerCase() == 'true' || raw == '1';
  }

  // ─────────────────────────────────────────────
  // Case 5: パスパラメータが存在するか確認
  // ─────────────────────────────────────────────
  static bool hasPath(String key) {
    return Get.parameters.containsKey(key) &&
        (Get.parameters[key]?.isNotEmpty ?? false);
  }

  // ─────────────────────────────────────────────
  // Case 6: クエリパラメータを String で取得
  // URL例: /search?q=flutter
  // ─────────────────────────────────────────────
  static String queryString(String key, {String fallback = ''}) {
    return Get.query[key] ?? fallback;
  }

  // ─────────────────────────────────────────────
  // Case 7: クエリパラメータを int で取得
  // URL例: /list?page=2
  // ─────────────────────────────────────────────
  static int queryInt(String key, {int fallback = 0}) {
    return int.tryParse(Get.query[key] ?? '') ?? fallback;
  }

  // ─────────────────────────────────────────────
  // Case 8: クエリパラメータを double で取得
  // URL例: /map?zoom=1.5
  // ─────────────────────────────────────────────
  static double queryDouble(String key, {double fallback = 0.0}) {
    return double.tryParse(Get.query[key] ?? '') ?? fallback;
  }

  // ─────────────────────────────────────────────
  // Case 9: クエリパラメータを bool で取得
  // URL例: /settings?darkMode=true
  // ─────────────────────────────────────────────
  static bool queryBool(String key, {bool fallback = false}) {
    final raw = Get.query[key];
    if (raw == null) return fallback;
    return raw.toLowerCase() == 'true' || raw == '1';
  }

  // ─────────────────────────────────────────────
  // Case 10: クエリパラメータが存在するか確認
  // ─────────────────────────────────────────────
  static bool hasQuery(String key) {
    return Get.query.containsKey(key) && (Get.query[key]?.isNotEmpty ?? false);
  }

  // ─────────────────────────────────────────────
  // Case 11: カンマ区切りクエリを List<String> で取得
  // URL例: /filter?tags=flutter,dart,mobile
  // ─────────────────────────────────────────────
  static List<String> queryList(String key, {String separator = ','}) {
    final raw = Get.query[key];
    if (raw == null || raw.isEmpty) return [];
    return raw.split(separator).map((e) => e.trim()).toList();
  }

  // ─────────────────────────────────────────────
  // Case 12: カンマ区切りクエリを List<int> で取得
  // URL例: /batch?ids=1,2,3
  // ─────────────────────────────────────────────
  static List<int> queryIntList(String key, {String separator = ','}) {
    final raw = Get.query[key];
    if (raw == null || raw.isEmpty) return [];
    return raw
        .split(separator)
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  // ─────────────────────────────────────────────
  // Case 13: 複数パスパラメータを Map で一括取得
  // ルート例: /user/:userId/post/:postId
  // ─────────────────────────────────────────────
  static Map<String, String> allPathParams() {
    return Map<String, String>.from(Get.parameters);
  }

  // ─────────────────────────────────────────────
  // Case 14: 全クエリパラメータを Map で一括取得
  // ─────────────────────────────────────────────
  static Map<String, String> allQueryParams() {
    return Map<String, String>.from(Get.query);
  }

  // ─────────────────────────────────────────────
  // Case 15: パスパラメータを DateTime で取得
  // ルート例: /schedule/:date → /schedule/2024-01-15
  // ─────────────────────────────────────────────
  static DateTime? pathDate(String key) {
    final raw = Get.parameters[key];
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ─────────────────────────────────────────────
  // Case 16: クエリパラメータを DateTime で取得
  // URL例: /events?from=2024-01-01
  // ─────────────────────────────────────────────
  static DateTime? queryDate(String key) {
    final raw = Get.query[key];
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ─────────────────────────────────────────────
  // Case 17: パスパラメータを Enum で取得
  // ルート例: /mode/:type → /mode/dark
  // ─────────────────────────────────────────────
  static T pathEnum<T extends Enum>(
    String key,
    List<T> values, {
    required T fallback,
  }) {
    final raw = Get.parameters[key] ?? '';
    return values.firstWhere(
      (e) => e.name == raw,
      orElse: () => fallback,
    );
  }

  // ─────────────────────────────────────────────
  // Case 18: クエリパラメータを Enum で取得
  // URL例: /sort?order=asc
  // ─────────────────────────────────────────────
  static T queryEnum<T extends Enum>(
    String key,
    List<T> values, {
    required T fallback,
  }) {
    final raw = Get.query[key] ?? '';
    return values.firstWhere(
      (e) => e.name == raw,
      orElse: () => fallback,
    );
  }
}

/// 各ケースのデモ用データ（画面表示に使用）
class UrlParamsCases {
  static const List<UrlParamCase> cases = [
    UrlParamCase(
      id: 1,
      title: 'パスパラメータ → String',
      route: '/user/:id',
      example: '/user/42',
      getter: "UrlParams.pathString('id')",
    ),
    UrlParamCase(
      id: 2,
      title: 'パスパラメータ → int',
      route: '/item/:id',
      example: '/item/10',
      getter: "UrlParams.pathInt('id')",
    ),
    UrlParamCase(
      id: 3,
      title: 'パスパラメータ → double',
      route: '/price/:amount',
      example: '/price/3.14',
      getter: "UrlParams.pathDouble('amount')",
    ),
    UrlParamCase(
      id: 4,
      title: 'パスパラメータ → bool',
      route: '/feature/:enabled',
      example: '/feature/true',
      getter: "UrlParams.pathBool('enabled')",
    ),
    UrlParamCase(
      id: 5,
      title: 'パスパラメータの存在確認',
      route: '/resource/:key',
      example: '/resource/abc',
      getter: "UrlParams.hasPath('key')",
    ),
    UrlParamCase(
      id: 6,
      title: 'クエリパラメータ → String',
      route: '/search',
      example: '/search?q=flutter',
      getter: "UrlParams.queryString('q')",
    ),
    UrlParamCase(
      id: 7,
      title: 'クエリパラメータ → int',
      route: '/list',
      example: '/list?page=2',
      getter: "UrlParams.queryInt('page')",
    ),
    UrlParamCase(
      id: 8,
      title: 'クエリパラメータ → double',
      route: '/map',
      example: '/map?zoom=1.5',
      getter: "UrlParams.queryDouble('zoom')",
    ),
    UrlParamCase(
      id: 9,
      title: 'クエリパラメータ → bool',
      route: '/settings',
      example: '/settings?darkMode=true',
      getter: "UrlParams.queryBool('darkMode')",
    ),
    UrlParamCase(
      id: 10,
      title: 'クエリパラメータの存在確認',
      route: '/page',
      example: '/page?debug=1',
      getter: "UrlParams.hasQuery('debug')",
    ),
    UrlParamCase(
      id: 11,
      title: 'カンマ区切りクエリ → List\u003cString\u003e',
      route: '/filter',
      example: '/filter?tags=flutter,dart',
      getter: "UrlParams.queryList('tags')",
    ),
    UrlParamCase(
      id: 12,
      title: 'カンマ区切りクエリ → List\u003cint\u003e',
      route: '/batch',
      example: '/batch?ids=1,2,3',
      getter: "UrlParams.queryIntList('ids')",
    ),
    UrlParamCase(
      id: 13,
      title: '全パスパラメータを Map で取得',
      route: '/user/:userId/post/:postId',
      example: '/user/1/post/99',
      getter: 'UrlParams.allPathParams()',
    ),
    UrlParamCase(
      id: 14,
      title: '全クエリパラメータを Map で取得',
      route: '/search',
      example: '/search?q=hello&lang=ja',
      getter: 'UrlParams.allQueryParams()',
    ),
    UrlParamCase(
      id: 15,
      title: 'パスパラメータ → DateTime',
      route: '/schedule/:date',
      example: '/schedule/2024-01-15',
      getter: "UrlParams.pathDate('date')",
    ),
    UrlParamCase(
      id: 16,
      title: 'クエリパラメータ → DateTime',
      route: '/events',
      example: '/events?from=2024-01-01',
      getter: "UrlParams.queryDate('from')",
    ),
    UrlParamCase(
      id: 17,
      title: 'パスパラメータ → Enum',
      route: '/mode/:type',
      example: '/mode/dark',
      getter: "UrlParams.pathEnum('type', values, fallback: fallback)",
    ),
    UrlParamCase(
      id: 18,
      title: 'クエリパラメータ → Enum',
      route: '/sort',
      example: '/sort?order=asc',
      getter: "UrlParams.queryEnum('order', values, fallback: fallback)",
    ),
  ];
}

class UrlParamCase {
  const UrlParamCase({
    required this.id,
    required this.title,
    required this.route,
    required this.example,
    required this.getter,
  });

  final int id;
  final String title;
  final String route;
  final String example;
  final String getter;
}
