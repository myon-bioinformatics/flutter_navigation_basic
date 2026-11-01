"""Pages must build validation source links pinned to the gated commit.

The Dart side is verified by validation_pattern_links_test.dart against the
rendered URLs (with and without SOURCE_REF); this checks the deploy wiring.
"""
from pathlib import Path
import json
import subprocess

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[2]


def test_pages_build_passes_the_gated_commit_as_source_ref():
    workflow = yaml.safe_load((ROOT / ".github/workflows/flutter-pages.yml").read_text(encoding="utf-8"))
    steps = [step for job in workflow["jobs"].values() for step in job.get("steps", [])]
    build = [step for step in steps if step.get("name") == "Build Flutter web"]
    assert len(build) == 1
    assert build[0]["env"]["GATED_SHA"] == "${{ steps.gated.outputs.sha }}"
    assert build[0]['uses'] == './.github/actions/build-companions'
    argv = json.loads(build[0]['with']['command'])
    assert '--dart-define=SOURCE_REF=${{ steps.gated.outputs.sha }}' in argv


@pytest.mark.parametrize('head,status,conclusion,accepted', [
    ('a' * 40, 'completed', 'success', True),
    ('b' * 40, 'completed', 'success', False),
    ('a' * 40, 'completed', 'failure', False),
    ('a' * 40, 'completed', 'cancelled', False),
    ('a' * 40, 'in_progress', None, False),
    (None, None, None, False),
])
def test_pages_gate_requires_completed_success_for_exact_sha(
    head, status, conclusion, accepted, monkeypatch,
):
    workflow = yaml.safe_load((ROOT / '.github/workflows/flutter-pages.yml').read_text())
    step = next(step for step in workflow['jobs']['build']['steps']
                if step.get('name') == 'Require Flutter success for target SHA')
    code = step['run'].split("python3 - <<'PY'\n", 1)[1].rsplit('\nPY', 1)[0]
    target = 'a' * 40
    monkeypatch.setenv('TARGET_SHA', target)
    monkeypatch.setenv('GITHUB_REPOSITORY', 'myon-bioinformatics/flutter_navigation_basic')
    runs = [] if head is None else [{
        'headSha': head, 'status': status, 'conclusion': conclusion,
        'databaseId': 123, 'event': 'push', 'url': 'https://example.test/run/123',
    }]

    def run_list(argv, *, text):
        assert argv[:3] == ['gh', 'run', 'list']
        assert argv[argv.index('--workflow') + 1] == 'Flutter'
        assert argv[argv.index('--commit') + 1] == target
        return json.dumps(runs)

    monkeypatch.setattr(subprocess, 'check_output', run_list)
    if accepted:
        exec(compile(code, 'flutter-pages.yml gate', 'exec'), {})
    else:
        with pytest.raises(SystemExit) as error:
            exec(compile(code, 'flutter-pages.yml gate', 'exec'), {})
        assert error.value.code == 1
