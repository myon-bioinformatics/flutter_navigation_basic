"""Execute the real Actions filters to guard the post-tool/ layout boundary."""
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[2]


def workflow(name):
    return yaml.safe_load((ROOT / '.github/workflows' / name).read_text())


@pytest.mark.parametrize('path', [
    'python/curl_request.py', 'python/tests/test_curl_request.py',
    'python/verify_timezone.py', 'python/requirements.txt',
    'python/vendor/markdown.py', 'python/tests/test_workflow_path_classification.py',
])
def test_python_only_skips_flutter(path, classify_workflow_asset):
    assert classify_workflow_asset(workflow('dart.yml'), path) == {
        'flutter': 'false', 'android': 'false', 'ios': 'false',
        'python': 'true', 'patterns': 'false',
    }
    result = classify_workflow_asset(workflow('non-dart.yml'), path)
    assert result['python'] == 'true'
    assert result['playwright'] == 'false'
    assert result['validation_browser'] == 'false'


@pytest.mark.parametrize('path', [
    'python/fixtures/timezone_cases.json',
    'python/fixtures/curl_request_cases.json',
    'python/fixtures/repository_metadata_v1.json',
    'python/pattern_contracts.py', 'python/metadata_contracts.py',
    'python/generate_pattern_contracts.py', 'python/generate_repository_metadata.py',
    'python/tests/test_pattern_contracts.py', 'python/tests/test_metadata_contracts.py',
    'python/generate_pattern_smoke_test.py',
    'python/check_pattern_smoke_mutations.py',
    'python/tests/test_pattern_smoke_generator.py',
])
def test_shared_python_inputs_run_both_consumers(path, classify_workflow_asset):
    result = classify_workflow_asset(workflow('dart.yml'), path)
    assert result['python'] == result['flutter'] == 'true'
    assert result['android'] == result['ios'] == 'false'
    assert classify_workflow_asset(workflow('non-dart.yml'), path)['python'] == 'true'


@pytest.mark.parametrize('path,patterns', [
    ('build_tools/inspect.dart', 'false'),
    ('javascript/node_test_runner.js', 'false'),
    ('docker/e2e-entrypoint.sh', 'false'),
    ('ci/flutter_core_test_paths.txt', 'false'),
    ('ci/flutter_pattern_test_paths.txt', 'true'),
])
def test_relocated_flutter_support_keeps_its_lane(path, patterns, classify_workflow_asset):
    result = classify_workflow_asset(workflow('dart.yml'), path)
    assert result['flutter'] == 'true'
    assert result['python'] == 'false'
    assert result['patterns'] == patterns


@pytest.mark.parametrize('paths', [
    ['python/curl_request.py', 'python/fixtures/timezone_cases.json'],
    ['python/fixtures/timezone_cases.json', 'python/curl_request.py'],
    ['python/curl_request.py', 'lib/main.dart'],
])
def test_mixed_changes_accumulate_flags(paths, classify_workflow_asset):
    result = classify_workflow_asset(workflow('dart.yml'), paths)
    assert result['flutter'] == result['python'] == 'true'


def test_main_push_keeps_full_matrix(classify_workflow_asset):
    assert set(classify_workflow_asset(workflow('dart.yml'), 'README.md', 'push').values()) == {'true'}


def test_non_dart_dispatch_keeps_full_matrix(classify_workflow_asset):
    assert set(classify_workflow_asset(workflow('non-dart.yml'), 'README.md', 'workflow_dispatch').values()) == {'true'}


def test_workflow_edits_keep_smoke_and_native_lanes(classify_workflow_asset):
    result = classify_workflow_asset(workflow('dart.yml'), '.github/workflows/dart.yml')
    assert result['flutter'] == result['android'] == result['ios'] == result['patterns'] == 'true'
    result = classify_workflow_asset(workflow('non-dart.yml'), '.github/workflows/non-dart.yml')
    assert set(result.values()) == {'true', 'false'}
    assert all(result[key] == 'true' for key in ('python', 'workflow', 'playwright', 'validation_browser', 'pattern_boundary'))


def test_non_dart_event_filters_have_no_duplicates():
    # PyYAML's YAML 1.1 loader interprets the Actions key `on` as True.
    events = workflow('non-dart.yml')[True]
    for event in ('push', 'pull_request'):
        paths = events[event]['paths']
        assert len(paths) == len(set(paths))


@pytest.mark.parametrize('name', ['dart.yml', 'non-dart.yml'])
def test_retargeted_refactor_runs_ci_on_main(name):
    assert workflow(name)[True]['pull_request']['branches'] == ['main']
