"""Independent metadata integrity decisions for assets and actual Dart exports."""
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
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
    if not (len(screens) == 198):
        raise AssertionError('metadata_contracts:24: validation failed')
    if not ({s.get('screenDataId', s.get('id')) for s in screens} == set(range(1, 199))):
        raise AssertionError('metadata_contracts:25: validation failed')
    for key in ('useCaseKey', 'emoji'):
        if not (len({s[key] for s in screens}) == 198):
            raise AssertionError(f'duplicate {key}')
    if not (len({s['emoji'].replace('\ufe0f', '') for s in screens}) == 198):
        raise AssertionError('metadata_contracts:28: validation failed')
    for screen in screens:
        identity = screen.get('screenDataId', screen.get('id'))
        domain = DOMAINS[(identity-1) % 18]
        if not (screen['domainKey'] == domain):
            raise AssertionError(f'{identity}: domain')
        if not (screen['templateJa'] == TEMPLATES[(identity-1)//18]):
            raise AssertionError(f'{identity}: template')
        if not (screen['useCaseKey'].startswith(domain + '.')):
            raise AssertionError('metadata_contracts:34: validation failed')
        if not (screen.get('templateOverride') is None):
            raise AssertionError('metadata_contracts:35: validation failed')
        for key in ('name', 'title', 'description', 'category', 'navigationPattern', 'apiPattern', 'themePattern', 'dataPattern'):
            if not (isinstance(screen[key], str) and screen[key]):
                raise AssertionError(f'{identity}: {key}')
        detail = screen.get('detail')
        if domain in ('integration', 'auth'):
            if not (isinstance(detail, dict)):
                raise AssertionError(f'{identity}: missing detail')
            for key in ('purpose', 'when', 'pitfall', 'snippet'):
                if not (isinstance(detail[key], str) and detail[key]):
                    raise AssertionError(f'{identity}: detail.{key}')
            if not (len(detail['points']) == 3 and all(isinstance(p, str) and p for p in detail['points'])):
                raise AssertionError('metadata_contracts:43: validation failed')
        else:
            if not (detail is None):
                raise AssertionError(f'{identity}: unexpected detail')


def validate_locales(locales):
    if not (set(locales) == LOCALES):
        raise AssertionError('metadata_contracts:49: validation failed')
    keys = set(locales['eng'])
    if not (keys):
        raise AssertionError('metadata_contracts:51: validation failed')
    if not (all(any(key.startswith(prefix) for key in keys) for prefix in NAMESPACES)):
        raise AssertionError('metadata_contracts:52: validation failed')
    for code, values in locales.items():
        if not (set(values) == keys):
            raise AssertionError(f'{code}: different keys')
        if not (all(isinstance(v, str) and v.strip() for v in values.values())):
            raise AssertionError(f'{code}: blank value')
        for key, placeholder in [('urlParameters.case', 'urlParamCaseId'), ('generic.screenFallbackTitle', 'screenDataId'), ('patternTemplate.screenIdLabel', 'screenDataId')]:
            if not ('{' + placeholder + '}' in values[key]):
                raise AssertionError(f'{code}:{key}')
        if not ('{id}' not in values['urlParameters.case']):
            raise AssertionError('metadata_contracts:58: validation failed')


def validate_export(document):
    if not (document['schemaVersion'] == 1):
        raise AssertionError('metadata_contracts:62: validation failed')
    validate_page_identities(document['pageIdentities'])
    if not (document['routes'] == ROUTES):
        raise AssertionError('metadata_contracts:64: validation failed')
    if not (len(document['locales']) == 11 and set(document['locales']) == LOCALES):
        raise AssertionError('metadata_contracts:65: validation failed')
    if not (set(document['namespaces']) == NAMESPACES):
        raise AssertionError('metadata_contracts:66: validation failed')
    validate_screens(document['screens'])
    # Verify the actual Dart decoder preserved every exported asset field.
    raw = json.loads((ROOT/'assets/screens.json').read_text())['screens']
    by_id = {s.get('screenDataId', s.get('id')): s for s in raw}
    for screen in document['screens']:
        source = by_id[screen['screenDataId']]
        for key, value in screen.items():
            expected = source.get('screenDataId', source.get('id')) if key == 'screenDataId' else source.get(key)
            if not (value == expected):
                raise AssertionError(f"Dart decode changed {screen['screenDataId']}:{key}")
    validate_locales(json.loads((ROOT/'assets/display/app_text.json').read_text())['locales'])


def validate_page_identities(data):
    emojis, aliases = data['emojis'], data['aliases']
    tools = {'/', '/hub', '/core/clipboard-shelf', '/tools/time/now-timeline',
             '/tools/location/coordinates', '/tools/media/photo-studio',
             '/tools/http/request-draft', '/examples/ui-showcase',
             '/examples/composition-generator', '/examples/irony-generator',
             '/examples/counter-playground', '/examples/external-integration/mcp'}
    if not (set(emojis) == tools | {f'/screen{i}' for i in range(1, 199)}):
        raise AssertionError('metadata_contracts:86: validation failed')
    normalized = [emoji.replace('\ufe0f', '') for emoji in emojis.values()]
    if not (all(normalized) and len(set(normalized)) == len(normalized)):
        raise AssertionError('duplicate page emoji')
    for alias, target in aliases.items():
        if not (alias not in emojis and target in emojis):
            raise AssertionError('invalid page alias')
    expected_aliases = {
        '/tools/location/bounding-box': '/tools/media/photo-studio',
        '/examples/composition-generator/seed': '/examples/composition-generator',
        '/examples/clipboard-workbench': '/core/clipboard-shelf',
        '/examples/external-integration/api': '/tools/http/request-draft',
        '/examples/mock-api': '/tools/http/request-draft',
        **{f'/examples/data-processing-interactions/{i}': f'/screen{i}'
           for i in (171, 172, 173, 174, 175, 183, 184)},
    }
    if not (aliases == expected_aliases):
        raise AssertionError('alias destination changed')
    screens = json.loads((ROOT/'assets/screens.json').read_text())['screens']
    for screen in screens:
        identity = screen.get('screenDataId', screen.get('id'))
        if not (emojis[f'/screen{identity}'] == screen['emoji']):
            raise AssertionError('header/Hub emoji drift')
    routes = data['publicRoutes']
    if not (set(data['titles']) == set(routes)):
        raise AssertionError('metadata_contracts:106: validation failed')
    for route in routes:
        if not (route in emojis or route in aliases):
            raise AssertionError(f'unregistered public route: {route}')
        expected = emojis[aliases.get(route, route)]
        if not (data['titles'][route] == 'Page ' + expected):
            raise AssertionError(f'wrong title identity: {route}')


if __name__ == '__main__':
    validate_export(json.loads(Path(sys.argv[1]).read_text()))
    print('Metadata contracts passed: Dart routes, 198 decoded screens, 11 locales')
