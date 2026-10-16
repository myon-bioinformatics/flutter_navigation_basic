"""Every curl import issue code has display text in all locales.

The editor shows ``display.text(issue.code)``; a missing key is rendered as the
raw code (``httpDraft.curl.error.shellMeta``). Codes come from both producers:
the Python parser and the Dart transport/legacy parser.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PREFIX = "httpDraft.curl."


def _codes() -> set[str]:
    python = (ROOT / "python/curl_request.py").read_text(encoding="utf-8")
    codes = {PREFIX + "error." + name for name in re.findall(r'_fail\("([A-Za-z]+)"\)', python)}
    codes |= {PREFIX + kind + "." + name
              for kind, name in re.findall(r'_PREFIX \+ "(error|warn)\.([A-Za-z]+)"', python)}
    for path in ("lib/shared/http/curl_import.dart", "lib/shared/http/curl_safe_subset.dart"):
        dart = (ROOT / path).read_text(encoding="utf-8")
        codes |= set(re.findall(r"httpDraft\.curl\.(?:error|warn)\.[A-Za-z]+", dart))
        codes |= {PREFIX + "error." + name for name in re.findall(r"_failure\('([A-Za-z]+)'\)", dart)}
    return codes


def test_scan_finds_both_producers():
    codes = _codes()
    # One code only Python emits, one only the Dart transport, one only legacy Dart.
    assert {PREFIX + "error.queryEncoding", PREFIX + "error.runtimeTimeout",
            PREFIX + "error.badMethod"} <= codes
    assert len(codes) >= 25


def test_every_curl_issue_code_has_text_in_every_locale():
    locales = json.loads((ROOT / "assets/display/app_text.json").read_text(encoding="utf-8"))["locales"]
    for locale, values in locales.items():
        missing = sorted(code for code in _codes() if not str(values.get(code, "")).strip())
        assert missing == [], f"{locale}: {missing}"


def test_curl_issue_text_needs_no_arguments():
    # The Python parser returns bare codes, so a {placeholder} would be shown literally.
    english = json.loads((ROOT / "assets/display/app_text.json").read_text(encoding="utf-8"))["locales"]["eng"]
    assert [code for code in _codes() if re.search(r"\{\w+\}", english[code])] == []
