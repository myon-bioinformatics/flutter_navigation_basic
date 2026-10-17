"""Pure-Dart diffs must retain full pytest, JUnit and receipt without duplication."""
import json
from pathlib import Path
from types import SimpleNamespace

import pytest
import yaml

import oracle_selection as selection
from test_flutter_navigation_basic_junit_workflow_contract import _run_plan

ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.parametrize('paths', [
    ['lib/main.dart'], ['lib/shared/clipboard/base64_image_bridge.dart'],
    ['test/shared/base64_image_bridge_test.dart'], ['lib/core/navigation/route_names.dart'],
    ['lib/features/api_patterns/pattern_001_to_099/pattern_003/model.dart'],
    ['assets/data_processing/cases.json'], ['assets/time/zone_table.json'],
    ['test/fixtures/photo_studio/import_compat/image.png'],
    ['python/metadata_contracts.py'], ['nested/requirements.txt'],
    ['lib/main.dart', 'python/metadata_contracts.py'],
    ['.github/workflows/non-dart.yml'],
])
def test_fallback_agrees_with_executed_primary_workflow(paths, classify_workflow_asset):
    workflow = yaml.safe_load((ROOT/'.github/workflows/non-dart.yml').read_text())
    actual = classify_workflow_asset(workflow, paths)
    primary = actual['python'] == 'true' or actual['workflow'] == 'true'
    assert selection.primary_owns(paths) == primary
    assert selection.fallback_required(paths) == (not primary)
    # Ordinary changes have exactly one full-suite owner.
    assert int(primary) + int(selection.fallback_required(paths)) == 1


def test_selector_changes_exercise_fallback_even_with_primary_tests():
    assert selection.fallback_required(['python/oracle_selection.py'])
    assert selection.fallback_required(['.github/workflows/dart.yml', 'python/test.py'])


def test_pure_dart_diff_selects_fallback_job_junit_and_receipt(classify_workflow_asset):
    workflow = yaml.safe_load((ROOT/'.github/workflows/dart.yml').read_text())
    actual = classify_workflow_asset(workflow, ['lib/shared/clipboard/base64_image_bridge.dart'])
    assert actual['flutter'] == 'true'
    assert selection.fallback_required(['lib/shared/clipboard/base64_image_bridge.dart'])
    jobs = workflow['jobs']
    fallback = jobs['python-oracle-fallback']
    assert fallback['if'] == "needs.changes.outputs.flutter == 'true' && needs.changes.outputs.oracle_fallback == 'true'"
    steps = fallback['steps']
    assert any('--junitxml=build/test-results/python-fallback.xml' in s.get('run', '') for s in steps)
    assert any(s.get('with', {}).get('name') == 'python-oracle-summary' for s in steps)
    run, reports = _run_plan(jobs['junit-plan'], {'FLUTTER': 'true', 'PATTERNS': 'false', 'PYTHON_FALLBACK': 'true'})
    assert run == 'true' and 'junit-python-fallback/python-fallback.xml' in reports
    assert 'python-oracle-fallback' in jobs['junit-identity']['needs']
    _, reports = _run_plan(jobs['junit-plan'], {'FLUTTER': 'true', 'PATTERNS': 'false', 'PYTHON_FALLBACK': 'false'})
    assert 'junit-python-fallback/python-fallback.xml' not in reports


def test_push_diff_is_used_instead_of_the_forced_flutter_python_flag(monkeypatch, tmp_path):
    calls = []
    def run(argv, **kwargs):
        calls.append(argv)
        return SimpleNamespace(stdout='lib/shared/clipboard/base64_image_bridge.dart\n')
    monkeypatch.setattr(selection.subprocess, 'run', run)
    output = tmp_path/'outputs'
    assert selection.main(['--base', 'before', '--head', 'after', '--output', str(output)]) == 0
    assert output.read_text() == 'run=true\n'
    assert calls[0] == ['git', 'diff', '--name-only', 'before', 'after']


def test_first_push_selects_fallback_without_unsafe_missing_base_diff(monkeypatch, tmp_path):
    monkeypatch.setattr(selection.subprocess, 'run', lambda *a, **kw: pytest.fail('zero base must not be diffed'))
    output = tmp_path/'outputs'
    assert selection.main(['--base', '0'*40, '--head', 'after', '--output', str(output)]) == 0
    assert output.read_text() == 'run=true\n'


def test_primary_classifier_cannot_own_a_workflow_that_is_not_triggered():
    path = 'lib/features/api_patterns/pattern_001_to_099/pattern_003/README.md'
    assert not selection.primary_owns([path])
    assert selection.fallback_required([path])
    assert selection.primary_owns([path, 'lib/main.dart'])
