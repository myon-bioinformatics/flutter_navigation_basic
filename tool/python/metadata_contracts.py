"""Independent metadata integrity decisions for assets and actual Dart exports."""
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
LOCALES = {'eng', 'jpn', 'fra', 'spa', 'por', 'ara', 'zho', 'rus', 'ind', 'deu', 'swa'}
NAMESPACES = {'common.', 'home.', 'coordinate.', 'photoStudio.', 'nowTimeline.'}
ROUTES = {
    'home': '/',
    'counterPlayground': '/examples/counter-playground',
    'ironyGenerator': '/examples/irony-generator',
    'compositionGenerator': '/examples/composition-generator',
    'compositionSeedGenerator': '/examples/composition-generator/seed',
    'boundingBox': '/tools/location/bounding-box',
}
DOMAINS = ('integration auth realtime data-fetch-cache data-transform search-filter '
           'input-form routing theme-design multiplatform accessibility settings-persistence '
           'state-management error-recovery observability testing-quality build-delivery security-privacy').split()
TEMPLATES = ['一覧', '詳細', 'フォーム', '検索', 'タブ', 'ボトムナビゲーション', 'ドロワー', 'ダイアログ', 'グリッド', '非同期', '設定']


def validate_screens(screens):
    assert len(screens) == 198
    assert {s.get('screenDataId', s.get('id')) for s in screens} == set(range(1, 199))
    for key in ('useCaseKey', 'emoji'):
        assert len({s[key] for s in screens}) == 198, f'duplicate {key}'
    assert len({s['emoji'].replace('\ufe0f', '') for s in screens}) == 198
    for screen in screens:
        identity = screen.get('screenDataId', screen.get('id'))
        domain = DOMAINS[(identity-1) % 18]
        assert screen['domainKey'] == domain, f'{identity}: domain'
        assert screen['templateJa'] == TEMPLATES[(identity-1)//18], f'{identity}: template'
        assert screen['useCaseKey'].startswith(domain + '.')
        assert screen.get('templateOverride') is None
        for key in ('name', 'title', 'description', 'category', 'navigationPattern', 'apiPattern', 'themePattern', 'dataPattern'):
            assert isinstance(screen[key], str) and screen[key], f'{identity}: {key}'
        detail = screen.get('detail')
        if domain in ('integration', 'auth'):
            assert isinstance(detail, dict), f'{identity}: missing detail'
            for key in ('purpose', 'when', 'pitfall', 'snippet'):
                assert isinstance(detail[key], str) and detail[key], f'{identity}: detail.{key}'
            assert len(detail['points']) == 3 and all(isinstance(p, str) and p for p in detail['points'])
        else:
            assert detail is None, f'{identity}: unexpected detail'


def validate_locales(locales):
    assert set(locales) == LOCALES
    keys = set(locales['eng'])
    assert keys
    assert all(any(key.startswith(prefix) for key in keys) for prefix in NAMESPACES)
    for code, values in locales.items():
        assert set(values) == keys, f'{code}: different keys'
        assert all(isinstance(v, str) and v.strip() for v in values.values()), f'{code}: blank value'
        for key, placeholder in [('urlParameters.case', 'urlParamCaseId'), ('generic.screenFallbackTitle', 'screenDataId'), ('patternTemplate.screenIdLabel', 'screenDataId')]:
            assert '{' + placeholder + '}' in values[key], f'{code}:{key}'
        assert '{id}' not in values['urlParameters.case']


def validate_export(document):
    assert document['schemaVersion'] == 1
    assert document['routes'] == ROUTES
    assert len(document['locales']) == 11 and set(document['locales']) == LOCALES
    assert set(document['namespaces']) == NAMESPACES
    validate_screens(document['screens'])
    # Verify the actual Dart decoder preserved every exported asset field.
    raw = json.loads((ROOT/'assets/screens.json').read_text())['screens']
    by_id = {s.get('screenDataId', s.get('id')): s for s in raw}
    for screen in document['screens']:
        source = by_id[screen['screenDataId']]
        for key, value in screen.items():
            expected = source.get('screenDataId', source.get('id')) if key == 'screenDataId' else source.get(key)
            assert value == expected, f"Dart decode changed {screen['screenDataId']}:{key}"
    validate_locales(json.loads((ROOT/'assets/display/app_text.json').read_text())['locales'])


if __name__ == '__main__':
    validate_export(json.loads(Path(sys.argv[1]).read_text()))
    print('Metadata contracts passed: Dart routes, 198 decoded screens, 11 locales')
