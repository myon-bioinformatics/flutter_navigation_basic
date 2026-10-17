"""Native SDK work must not delay unrelated web-only changes."""
from fnmatch import fnmatchcase
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[2]


def native_workflow():
    return yaml.safe_load((ROOT / '.github/workflows/ios-native.yml').read_text())


@pytest.mark.parametrize('path,expected', [
    ('ios/Runner/ImageNormalize.swift', True),
    ('ios/Runner/Info.plist', True),
    ('pubspec.lock', True),
    ('pubspec.yaml', True),
    ('lib/features/photo_studio/data/native_image_normalize_adapter_io.dart', True),
    ('lib/features/photo_studio/data/photo_import_limits.dart', True),
    ('test/fixtures/photo_studio/import_compat/png_opaque_64x32.png', True),
    ('.github/workflows/ios-native.yml', True),
    ('lib/features/clipboard_shelf/presentation/clipboard_shelf_page.dart', False),
    ('web/index.html', False),
    ('python/test.py', False),
    ('docs/workflow-inventory.md', False),
])
def test_native_ci_trigger_scope(path, expected):
    events = native_workflow()[True]
    for event in ('pull_request', 'push'):
        assert any(fnmatchcase(path, pattern) for pattern in events[event]['paths']) == expected


def test_native_sdk_pin_matches_primary_flutter_gate():
    dart = yaml.safe_load((ROOT / '.github/workflows/dart.yml').read_text())
    pin = next(step['with']['flutter-version'] for step in dart['jobs']['gate']['steps']
               if step.get('uses', '').startswith('subosito/flutter-action@'))
    for job in native_workflow()['jobs'].values():
        assert next(step['with']['flutter-version'] for step in job['steps']
                    if step.get('uses', '').startswith('subosito/flutter-action@')) == pin


def test_pages_keeps_exact_flutter_gate_and_native_workflow_stays_manual_runnable():
    events = native_workflow()[True]
    assert 'workflow_dispatch' in events
    pages = yaml.safe_load((ROOT / '.github/workflows/flutter-pages.yml').read_text())
    assert pages[True]['workflow_run']['workflows'] == ['Flutter']
    assert set(native_workflow()['permissions']) == {'contents'}
