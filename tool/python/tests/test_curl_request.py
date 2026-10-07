"""Pure curl import contracts; no curl process or network service is started."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys

import pytest

PYTHON_DIR = Path(__file__).resolve().parents[1]
CLI = PYTHON_DIR / "curl_request.py"
FIXTURE = PYTHON_DIR / "fixtures/curl_request_cases.json"
CASES = json.loads(FIXTURE.read_text(encoding="utf-8"))["cases"]
SPEC = importlib.util.spec_from_file_location("curl_request_under_test", CLI)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def invoke(raw: bytes, *args: str, script: Path = CLI):
    return subprocess.run([sys.executable, "-I", "-S", str(script), *args],
                          input=raw, capture_output=True, timeout=5)


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["id"])
def test_shared_import_contract(case):
    assert MODULE.parse_curl(case["input"]) == case["expected"]


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["id"])
def test_cli_shared_contract(case):
    result = invoke(case["input"].encode("utf-8"))
    assert result.returncode == (0 if case["expected"]["ok"] else 2)
    assert json.loads(result.stdout) == case["expected"]
    assert result.stderr == b""


def test_isolated_file_input_without_repository(tmp_path):
    standalone = tmp_path / "parser.py"
    shutil.copyfile(CLI, standalone)
    vendor = tmp_path / "vendor"
    vendor.mkdir()
    shutil.copyfile(PYTHON_DIR / "vendor" / "cli_args.py", vendor / "cli_args.py")
    source = tmp_path / "入力 curl.txt"
    source.write_text("curl -G -d 'q=%E7%8C%AB' https://example.com/", encoding="utf-8")
    result = invoke(b"", "--input", str(source), script=standalone)
    assert result.returncode == 0
    assert json.loads(result.stdout)["draft"]["query"][0]["value"] == "猫"


@pytest.mark.parametrize("raw,code", [
    (b"x" * (MODULE.MAX_INPUT_BYTES + 1), "inputTooLarge"),
    (b"curl https://example.com/\0", "nul"),
    (b"\xff", "inputRead"),
    (b"curl -G -d 'x=%ZZ' https://example.com/", "queryEncoding"),
    (b"curl -G -d 'x=%FF' https://example.com/", "queryEncoding"),
    (b"curl " + b"x " * MODULE.MAX_TOKENS, "tooManyTokens"),
])
def test_additional_invalid_input_is_bounded_and_structured(raw, code):
    result = invoke(raw)
    payload = json.loads(result.stdout)
    assert result.returncode == 2
    assert payload["draft"] is None
    assert payload["errors"] == ["httpDraft.curl.error." + code]
    assert result.stderr == b""


def test_exact_input_size_limit():
    prefix = "curl https://example.com/"
    raw = prefix + " " * (MODULE.MAX_INPUT_BYTES - len(prefix))
    assert MODULE.parse_curl(raw)["ok"]
    assert MODULE.parse_curl(raw + " ")["errors"] == ["httpDraft.curl.error.inputTooLarge"]


def test_size_limit_is_utf8_bytes_not_character_count():
    assert MODULE.parse_curl("猫" * 22_000)["errors"] == ["httpDraft.curl.error.inputTooLarge"]


def test_missing_file_diagnostic_does_not_expose_path(tmp_path):
    secret = tmp_path / "do-not-log-this-private-name"
    result = invoke(b"", "--input", str(secret))
    assert result.returncode == 2
    assert b"do-not-log" not in result.stdout + result.stderr
    assert json.loads(result.stdout)["errors"] == ["httpDraft.curl.error.inputRead"]


def test_parse_never_executes_commands_or_reads_at_files(tmp_path):
    target = tmp_path / "must-not-exist"
    result = invoke(f"curl https://example.com/ ; touch {target}".encode())
    assert result.returncode == 2
    assert not target.exists()
    private_file = tmp_path / "private.txt"
    private_file.write_text("FILE_CONTENT_SENTINEL", encoding="utf-8")
    result = invoke(f"curl -d @{private_file} https://example.com/".encode())
    assert result.returncode == 2
    assert b"FILE_CONTENT_SENTINEL" not in result.stdout + result.stderr


def test_direct_api_invalid_types_and_surrogates():
    assert MODULE.parse_curl(None)["errors"] == ["httpDraft.curl.error.inputType"]
    assert MODULE.parse_curl("\ud800")["errors"] == ["httpDraft.curl.error.encoding"]


def test_expansion_is_literal_and_diagnostics_exclude_input():
    raw = "curl -d '$SECRET;`id`' https://example.com/"
    assert MODULE.parse_curl(raw)["draft"]["rawBody"] == "$SECRET;`id`"
    payload = MODULE.parse_curl("curl --unknown=SECRET_SENTINEL https://example.com/")
    assert "SECRET_SENTINEL" not in json.dumps(payload)


def test_help_has_no_input_side_effects():
    result = invoke(b"", "--help")
    assert result.returncode == 0
    assert b"--input" in result.stdout


@pytest.mark.parametrize("args", [
    ("--unknown", "SECRET_SENTINEL"),
    ("unexpected-positional",),
    ("--input",),
])
def test_invalid_cli_arguments_are_structured_and_secret_free(args):
    result = invoke(b"", *args)
    assert result.returncode == 2
    assert result.stderr == b""
    payload = json.loads(result.stdout)
    assert payload == {
        "ok": False,
        "draft": None,
        "errors": ["httpDraft.curl.error.arguments"],
        "warnings": [],
    }
    assert b"SECRET_SENTINEL" not in result.stdout


def test_http_page_no_longer_depends_on_legacy_curl_parser_for_export():
    page = (PYTHON_DIR.parents[1] / "lib/features/http_request_draft/presentation/http_request_draft_page.dart").read_text(
        encoding="utf-8"
    )
    assert "curl_safe_subset.dart" not in page
    assert "CurlSafeSubset." not in page
    assert "RequestDraftCodec.toCurl" in page


def test_python_bridge_result_type_is_not_owned_by_legacy_parser():
    root = PYTHON_DIR.parents[1]
    legacy = (root / "lib/shared/http/curl_safe_subset.dart").read_text(encoding="utf-8")
    bridge = (root / "lib/shared/http/curl_import.dart").read_text(encoding="utf-8")
    shared = (root / "lib/shared/http/curl_import_result.dart").read_text(encoding="utf-8")
    assert "class CurlImportResult" not in legacy
    assert "class CurlImportResult" in shared
    assert "curl_import_result.dart" in bridge
