"""SDK-only execution must use production source and never reuse stale results."""
import json
from pathlib import Path
import sys
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import dart_contracts as cli
from test_pattern_contracts import valid_document


def test_current_actual_producer_graph_has_no_flutter_or_external_package():
    sources = cli.source_graph()
    assert len(sources) == 1188
    assert 'build_tools/export_pattern_contracts.dart' in sources
    assert 'lib/features/api_patterns/pattern_001_to_099/pattern_001/model.dart' in sources
    assert all(len(sha) == 64 for sha in sources.values())
    config = cli.package_config()
    assert config['packages'] == [{'name': 'flutter_application_1', 'rootUri': cli.ROOT.as_uri()+'/',
                                   'packageUri': 'lib/', 'languageVersion': '3.12'}]


@pytest.mark.parametrize('uri', ['dart:ui', 'package:flutter/material.dart', 'package:get/get.dart', '../outside.dart'])
def test_preflight_rejects_unavailable_dependencies(tmp_path, uri):
    entry = tmp_path/'entry.dart'
    entry.write_text(f"import '{uri}';\nvoid main() {{}}")
    with pytest.raises((ValueError, OSError)):
        cli.source_graph(entry, tmp_path)


def test_conditional_import_cannot_hide_flutter_dependency(tmp_path):
    (tmp_path/'okay.dart').write_text('void okay() {}')
    entry = tmp_path/'entry.dart'
    entry.write_text("import 'okay.dart' if (dart.library.ui) 'package:flutter/widgets.dart';")
    with pytest.raises(ValueError, match='external dependency'):
        cli.source_graph(entry, tmp_path)


def test_preflight_does_not_launch_runtime_or_claim_dart_executed(monkeypatch, capsys):
    monkeypatch.setattr(cli.subprocess, 'run', lambda *a, **kw: pytest.fail('preflight must not run a process'))
    assert cli.main(['--preflight']) == 0
    data = json.loads(capsys.readouterr().out)
    assert data['current_dart_executed'] is False
    assert data['scope'] == 'source-preflight'


def test_missing_dart_is_an_error_not_a_pass(monkeypatch):
    monkeypatch.setattr(cli.shutil, 'which', lambda _: None)
    assert cli.main([]) == 2


def test_current_dart_results_reach_independent_oracle_and_exact_junit(monkeypatch, tmp_path):
    calls = []
    monkeypatch.setattr(cli.shutil, 'which', lambda _: '/sdk/bin/dart')

    def run(argv, **kwargs):
        calls.append(argv)
        if '--version' in argv:
            return SimpleNamespace(stdout='Dart SDK test-version', stderr='', returncode=0)
        assert '--disable-dart-dev' in argv
        assert argv[-2] == str(cli.ENTRY)
        assert argv[2].startswith('--packages=')
        assert not any('flutter' == item or 'pub' == item for item in argv)
        Path(argv[-1]).write_text(json.dumps(valid_document()))
        return SimpleNamespace(returncode=0)

    monkeypatch.setattr(cli.subprocess, 'run', run)
    assert cli.main(['--output-dir', str(tmp_path)]) == 0
    assert len(calls) == 2
    evidence = json.loads((tmp_path/'dart-pure-run.json').read_text())
    assert evidence['current_dart_executed'] is True
    assert evidence['failures'] == {}
    import xml.etree.ElementTree as ET
    root = ET.parse(tmp_path/'pattern-contracts.xml').getroot()
    assert root.get('tests') == '595' and root.get('failures') == '0'


def test_runtime_failure_cannot_reuse_previous_success(monkeypatch, tmp_path):
    for name in ('pattern-contracts.json', 'pattern-contracts.xml', 'dart-pure-run.json'):
        (tmp_path/name).write_text('old successful evidence')
    monkeypatch.setattr(cli.shutil, 'which', lambda _: '/sdk/bin/dart')
    monkeypatch.setattr(cli.subprocess, 'run', lambda *a, **kw: SimpleNamespace(returncode=17, stdout='', stderr=''))
    assert cli.main(['--output-dir', str(tmp_path)]) == 17
    assert not (tmp_path/'pattern-contracts.json').exists()
    assert not (tmp_path/'pattern-contracts.xml').exists()
    assert not (tmp_path/'dart-pure-run.json').exists()
