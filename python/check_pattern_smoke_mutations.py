#!/usr/bin/env python3
"""Prove the generated Flutter suite rejects thrown/empty production services.

Run after flutter pub get. Expected failures are retained as raw JSONL + JUnit
outside the normal junit-* artifact set; only a verified rejection passes CI.
The production source is always restored, including on timeout or interruption.
"""
from __future__ import annotations

import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

from flutter_machine_junit import convert

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "lib/features/ui_theme_patterns/pattern_100_to_198/pattern_147/service.dart"
SUITE = "test/features/catalogue_smoke_patterns/pattern_catalogue_smoke_test.dart"
IDENTITY = "ui_theme_patterns/pattern_147"
SENTINEL = "pattern-smoke-thrown-sentinel"


def main() -> int:
    output = ROOT / "build/test-results/pattern-smoke-mutations"
    output.mkdir(parents=True, exist_ok=True)
    original = SERVICE.read_bytes()
    receipts = []
    try:
        for name, body, summary in (
            ("exception", f"throw StateError('{SENTINEL}');", SENTINEL),
            ("empty", "return Pattern147Result(message: '');", "empty message"),
        ):
            SERVICE.write_text(
                "import 'model.dart';\nclass Pattern147Service {\n"
                f"  Future<Pattern147Result> run() async {{ {body} }}\n}}\n",
                encoding="utf-8",
            )
            events = output / f"{name}.jsonl"
            result = subprocess.run(
                ["flutter", "test", SUITE, "--plain-name",
                 "ui_theme_patterns every service.run() completes with a non-empty message",
                 "--file-reporter", f"json:{events}"],
                cwd=ROOT, capture_output=True, text=True, encoding="utf-8",
                errors="replace", timeout=180,
            )
            (output / f"{name}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
            if result.returncode != 1:
                raise RuntimeError(f"{name}: expected test exit 1, got {result.returncode}")
            report = output / f"{name}.xml"
            convert(events, report)
            failures = ET.parse(report).findall(".//testcase/failure")
            if len(failures) != 1:
                raise RuntimeError(f"{name}: expected one actual test failure, got {len(failures)}")
            failure = ET.tostring(failures[0], encoding="unicode")
            if IDENTITY not in failure or summary not in failure:
                raise RuntimeError(f"{name}: missing pattern ID or exception/empty summary in JUnit")
            receipts.append({"mutation": name, "exitCode": result.returncode,
                             "pattern": IDENTITY, "summary": summary, "rejected": True})
            print(f"Verified {name}: {IDENTITY}: {summary}")
    finally:
        SERVICE.write_bytes(original)
        (output / "receipt.json").write_text(json.dumps(receipts, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
