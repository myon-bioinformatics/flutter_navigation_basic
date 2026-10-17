"""Historical evidence must fail closed on missing/corrupt/mixed page captures."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_web_observations as check
from web_page_catalogue import catalogue


def receipt(directory, route='/core/clipboard-shelf'):
    directory.mkdir(parents=True, exist_ok=True)
    png = (Path(__file__).resolve().parents[2] / 'test/fixtures/photo_studio/import_compat/png_opaque_64x32.png').read_bytes()
    (directory / 'web-observation.png').write_bytes(png)
    data = {'schema': 'flutter-web-observation/1', 'test': 'test '+route, 'project': 'chromium',
            'status': 'passed', 'expected_status': 'passed', 'build_sha': 'a'*40,
            'url': 'https://example.test/app/#'+route, 'capture_errors': [], 'errors': [],
            'runtime': {'browser': 'chromium', 'browser_version': '123', 'display': {
                'viewport': {'width': 100, 'height': 100}, 'device_scale_factor': 1,
                'controls': [{'label': 'Remove', 'visible': True,
                              'box': {'x': 1, 'y': 2, 'width': 20, 'height': 30}}]}},
            'fixture': None, 'screenshot': {'file': 'web-observation.png', 'bytes': len(png),
                                          'sha256': hashlib.sha256(png).hexdigest()},
            'catalogue': {'schema': 'flutter-web-page-catalogue/1', 'routes': ['/a', '/b'], 'projects': ['chromium'], 'sources': {}}}
    (directory / 'web-observation.json').write_text(json.dumps(data))
    return data


def test_saved_evidence_checks_without_browser_node_or_site(tmp_path):
    receipt(tmp_path)
    command = [sys.executable, '-S', str(Path(check.__file__)), str(tmp_path/'web-observation.json'), '--expected-sha', 'a'*40]
    result = subprocess.run(command, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)['current_code_executed'] is False
    assert check.main(command[3:]+['--expected-sha', 'b'*40]) == 1


@pytest.mark.parametrize('mutation', ['failed', 'skipped', 'capture', 'empty', 'nan', 'pageerror', 'malformed', 'traversal', 'hash'])
def test_bad_or_incomplete_evidence_rejected(tmp_path, mutation):
    data = receipt(tmp_path)
    if mutation in ('failed', 'skipped'):
        data['status'] = mutation
    elif mutation == 'capture':
        data['capture_errors'] = ['timeout']
    elif mutation == 'empty':
        data['runtime']['display']['controls'] = []
    elif mutation == 'nan':
        data['runtime']['display']['controls'][0]['box']['x'] = float('nan')
    elif mutation == 'pageerror':
        data['errors'] = [{'kind': 'pageerror', 'message': 'boom'}]
    elif mutation == 'malformed':
        data['runtime'] = None
    elif mutation == 'traversal':
        data['screenshot']['file'] = '../other.png'
    else:
        (tmp_path/'web-observation.png').write_bytes(b'altered')
    assert check.validate(data, tmp_path)


def test_layout_comparison_checks_viewport_labels_duplicates_and_tolerance(tmp_path):
    before = receipt(tmp_path)
    after = copy.deepcopy(before)
    after['runtime']['display']['controls'][0]['box']['x'] += 1
    assert check.compare(before, after, 2) == []
    assert 'Remove: geometry mismatch' in check.compare(before, after, 0)
    after['runtime']['display']['controls'].append(copy.deepcopy(after['runtime']['display']['controls'][0]))
    assert 'control labels/count mismatch' in check.compare(before, after, 2)
    after['runtime']['display']['viewport']['width'] += 1
    assert 'viewport mismatch' in check.compare(before, after, 2)


def test_all_pages_cannot_pass_with_missing_duplicate_or_mixed_receipts(tmp_path):
    receipt(tmp_path/'a', '/a')
    assert check.main([str(tmp_path)]) == 1  # /b missing
    receipt(tmp_path/'b', '/b')
    assert check.main([str(tmp_path)]) == 0
    receipt(tmp_path/'duplicate', '/b')
    assert check.main([str(tmp_path)]) == 1


def test_catalogue_reuses_existing_registry_and_all_198_numbered_routes():
    data = catalogue()
    assert len(data['routes']) == 215
    assert len(set(data['routes'])) == 215
    assert all('/screen'+str(i) in data['routes'] for i in range(1, 199))
    assert {'/', '/hub', '/tools/media/photo-studio', '/core/clipboard-shelf',
            '/examples/mock-api', '/examples/external-integration/api'} <= set(data['routes'])
    assert all(len(value) == 64 for value in data['sources'].values())


def test_all_page_cli_reuses_one_existing_runner_and_can_filter(monkeypatch):
    import playwright
    from types import SimpleNamespace
    calls = []
    monkeypatch.setattr(playwright, '_playwright_prefix', lambda: ['node', 'cli.js'])
    monkeypatch.setattr(playwright.subprocess, 'run', lambda argv, **kw: calls.append((argv, kw)) or SimpleNamespace(returncode=0))
    assert playwright.main(['pages', '--base-url', 'https://example.test/app/', '--light', '--route', '/hub']) == 0
    argv, options = calls[0]
    assert '--project=chromium' in argv
    assert 'tests/page_observations.spec.ts' in argv
    assert json.loads(options['env']['FLUTTER_WEB_ROUTES'])['routes'] == ['/hub']
    assert options['env']['FLUTTER_WEB_LIGHT'] == '1'
    assert playwright.main(['pages', '--base-url', 'https://example.test/', '--route', '/unknown']) == 2
    assert len(calls) == 1


def test_directory_baseline_detects_geometry_changes_and_missing_projects(tmp_path):
    new, old = tmp_path/'new', tmp_path/'old'
    for directory in (new, old):
        receipt(directory/'a', '/a')
        receipt(directory/'b', '/b')
    assert check.main([str(new), '--baseline', str(old)]) == 0
    path = new/'a'/'web-observation.json'
    data = json.loads(path.read_text())
    data['runtime']['display']['controls'][0]['box']['y'] += 10
    path.write_text(json.dumps(data))
    assert check.main([str(new), '--baseline', str(old)]) == 1
    for path in new.rglob('web-observation.json'):
        data = json.loads(path.read_text())
        data['catalogue']['projects'].append('webkit')
        path.write_text(json.dumps(data))
    assert check.main([str(new)]) == 1


def test_cli_remainder_separator_reaches_runner_as_options(monkeypatch):
    import playwright
    calls = []
    monkeypatch.setattr(playwright, '_playwright_prefix', lambda: ['node', 'cli.js'])
    monkeypatch.setattr(playwright, '_run', lambda argv, **kw: calls.append(argv) or 0)
    assert playwright.main(['pages', '--base-url', 'https://example.test/', '--', '--list']) == 0
    assert calls[0][-1] == '--list'
    assert '--' not in calls[0]


def test_flutter_home_url_normalization_is_not_a_missing_page(tmp_path):
    data = receipt(tmp_path/'home', '/')
    data['url'] = 'https://example.test/app/'
    data['catalogue']['routes'] = ['/']
    (tmp_path/'home'/'web-observation.json').write_text(json.dumps(data))
    assert check.main([str(tmp_path)]) == 0
    other = copy.deepcopy(data)
    other['url'] += '#/'
    assert check.compare(data, other, 2) == []


def test_exploration_seed_is_forwarded_once_without_mutating_parent_environment(monkeypatch):
    import playwright
    from types import SimpleNamespace
    calls = []
    monkeypatch.setenv('FLUTTER_WEB_EXPLORE_SEED', 'parent')
    monkeypatch.setattr(playwright, '_playwright_prefix', lambda: ['node', 'cli.js'])
    monkeypatch.setattr(playwright.subprocess, 'run', lambda argv, **kw: calls.append(kw) or SimpleNamespace(returncode=0))
    assert playwright.main(['pages', '--base-url', 'https://example.test/', '--seed', 'replay', '--explore-steps', '3', '--route', '/hub']) == 0
    assert calls[0]['env']['FLUTTER_WEB_EXPLORE_SEED'] == 'replay'
    assert calls[0]['env']['FLUTTER_WEB_EXPLORE_STEPS'] == '3'
    assert playwright.os.environ['FLUTTER_WEB_EXPLORE_SEED'] == 'parent'
    with pytest.raises(SystemExit) as error:
        playwright.main(['pages', '--base-url', 'https://example.test/', '--explore-steps', '21'])
    assert error.value.code == 2


def test_matching_hash_cannot_make_a_header_only_png_valid(tmp_path):
    data = receipt(tmp_path)
    raw = b'\x89PNG\r\n\x1a\nnot-a-complete-png'
    (tmp_path / 'web-observation.png').write_bytes(raw)
    data['screenshot'].update(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())
    assert check.validate(data, tmp_path)
