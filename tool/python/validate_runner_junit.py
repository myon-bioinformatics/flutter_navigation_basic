#!/usr/bin/env python3
"""Validate a runner's native JUnit XML before adding it to shared collection.

This is intentionally independent of pytest; missing, malformed and empty
reports fail closed. Standard-library only.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def inspect(path: Path) -> dict[str, int]:
    if not path.is_file() or path.is_symlink():
        raise ValueError("JUnit report is missing or not a regular file")
    root = ET.fromstring(path.read_bytes())
    if root.tag not in ("testsuite", "testsuites"):
        raise ValueError("not a JUnit testsuite")
    cases = root.findall(".//testcase")
    if root.tag == "testsuite":
        cases = root.findall("testcase")
    if not cases:
        raise ValueError("JUnit report contains no testcases")
    failures = sum(bool(c.findall("failure")) for c in cases)
    errors = sum(bool(c.findall("error")) for c in cases)
    skipped = sum(bool(c.findall("skipped")) for c in cases)
    if any(not c.get("name") for c in cases):
        raise ValueError("JUnit testcase without name")
    return {"tests": len(cases), "failures": failures, "errors": errors,
            "skipped": skipped}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    args = parser.parse_args(argv)
    try:
        stats = inspect(args.report)
    except (ValueError, OSError, ET.ParseError) as error:
        print(f"invalid JUnit: {error}", file=sys.stderr)
        return 2
    print(" ".join(f"{key}={value}" for key, value in stats.items()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
