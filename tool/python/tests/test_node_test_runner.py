"""Regression tests for the stdlib Node runner and its failure evidence."""
import json
import shutil
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from node_test_runner import NodeEvidenceError, read_junit, run_node


def test_native_junit_failure_and_skip(tmp_path):
    path = tmp_path / "node.xml"
    path.write_text('<testsuites><testcase name="ok"/><testcase name="bad"><failure message="boom">stack</failure></testcase><testcase name="skip"><skipped/></testcase></testsuites>')
    assert read_junit(path) == {"passed": 1, "failed": 1, "skipped": 1, "total": 3,
                                "failures": [{"name": "bad", "message": "boom"}], "names": ["ok", "bad", "skip"]}


@pytest.mark.parametrize("xml", ["<broken", "<other/>", "<testsuites/>",
                                  "<testsuites><testcase/></testsuites>"])
def test_reject_invalid_evidence(tmp_path, xml):
    path = tmp_path / "node.xml"
    path.write_text(xml)
    with pytest.raises(NodeEvidenceError):
        read_junit(path)


@pytest.mark.skipif(shutil.which("node") is None, reason="Node is optional in Python-only lanes")
def test_real_node_success_and_failure(tmp_path):
    js = tmp_path / "checks.test.mjs"
    js.write_text("import test from 'node:test';\ntest('passes', () => {});\ntest('fails', () => {throw new Error('sentinel failure')});\n")
    report = tmp_path / "node.xml"
    receipt = tmp_path / "summary.json"
    assert run_node(root=tmp_path, files=[js.name], report=report, receipt=receipt) == 1
    data = json.loads(receipt.read_text())
    assert data["failed"] == 1 and data["passed"] == 1
    assert "sentinel failure" in data["failures"][0]["message"]
    assert run_node(root=tmp_path, files=[js.name], report=report, receipt=receipt,
                    name_pattern="^passes$") == 0
    assert json.loads(receipt.read_text())["failed"] == 0


def test_missing_node_does_not_accept_stale_report(tmp_path):
    report = tmp_path / "node.xml"
    report.write_text('<testsuites><testcase name="stale"/></testsuites>')
    assert run_node(root=tmp_path, files=["x.test.mjs"], report=report,
                    node="__node_does_not_exist__") == 127
    assert not report.exists()


def test_invalid_regex_and_empty_file_selection(tmp_path):
    assert run_node(root=tmp_path, files=[], report=tmp_path / "node.xml") == 2
    assert run_node(root=tmp_path, files=["x.test.mjs"], report=tmp_path / "node.xml",
                    name_pattern="[") != 0


@pytest.mark.skipif(shutil.which("node") is None, reason="Node unavailable")
def test_filter_matching_nothing_fails_closed(tmp_path):
    js = tmp_path / "checks.test.mjs"
    js.write_text("import test from 'node:test'; test('exists', () => {});")
    report = tmp_path / "node.xml"
    receipt = tmp_path / "summary.json"
    receipt.write_text('{"ok":true}')
    assert run_node(root=tmp_path, files=[js.name], report=report, receipt=receipt,
                    name_pattern="^never-matches$") != 0
    assert not receipt.exists()


def test_missing_node_clears_stale_receipt(tmp_path):
    report = tmp_path / "node.xml"
    receipt = tmp_path / "summary.json"
    receipt.write_text('{"ok":true}')
    assert run_node(root=tmp_path, files=["x.test.mjs"], report=report,
                    receipt=receipt, node="__node_does_not_exist__") == 127
    assert not receipt.exists()


@pytest.mark.skipif(shutil.which("node") is None, reason="Node unavailable")
@pytest.mark.parametrize("pattern", ["Clipboard", "/COPIES/i"])
def test_node_js_regex_and_describe_name_are_authoritative(tmp_path, pattern):
    js = tmp_path / "clipboard.test.mjs"
    js.write_text(
        "import { describe, it } from 'node:test'; "
        "describe('Clipboard', () => { "
        "it('copies', () => {}); it('COPIES', () => {}); });"
    )
    report = tmp_path / "node.xml"
    assert run_node(root=tmp_path, files=[js.name], report=report,
                    name_pattern=pattern) == 0
    assert read_junit(report)["passed"] >= 1
