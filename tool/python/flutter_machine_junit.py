#!/usr/bin/env python3
"""Convert Flutter machine JSON test events into per-case JUnit XML (stdlib).

Follows the Dart test JSON reporter protocol:
- skipped tests report ``result: "success"`` with ``skipped: true``;
- hidden pseudo-tests (successful ``loading <file>``) are dropped, but a failed
  load stays visible so compile/load errors are never lost;
- ``classname`` is the suite path so identical test names in different files
  keep distinct identities.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

RESULTS = ("success", "failure", "error")


def convert(source: Path, destination: Path) -> int:
    suites: dict[int, str] = {}
    tests: dict[int, dict] = {}
    done = False
    for line in source.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        event = json.loads(line)
        if not isinstance(event, dict):
            raise ValueError("invalid Flutter event")
        kind = event.get("type")
        if kind == "suite":
            suite = event.get("suite") or {}
            if type(suite.get("id")) is int:
                suites[suite["id"]] = str(suite.get("path") or "flutter")
        elif kind == "testStart":
            test = event.get("test") or {}
            identifier = test.get("id")
            if type(identifier) is not int or identifier in tests:
                raise ValueError("duplicate or missing Flutter test ID")
            tests[identifier] = {
                "name": str(test.get("name") or ""),
                "suite": suites.get(test.get("suiteID"), "flutter"),
                "skip_reason": str((test.get("metadata") or {}).get("skipReason") or ""),
                "result": None, "skipped": False, "hidden": False, "errors": [],
            }
        elif kind == "error":
            identifier = event.get("testID")
            if identifier not in tests:
                raise ValueError("orphan Flutter error")
            tests[identifier]["errors"].append(
                "\n".join(str(event.get(k)) for k in ("error", "stackTrace") if event.get(k)))
        elif kind == "testDone":
            identifier = event.get("testID")
            if identifier not in tests or tests[identifier]["result"] is not None:
                raise ValueError("orphan or duplicate Flutter completion")
            item = tests[identifier]
            item["result"] = event.get("result")
            item["skipped"] = bool(event.get("skipped"))
            item["hidden"] = bool(event.get("hidden"))
        elif kind == "done":
            done = True
    if not done or any(not t["name"] or t["result"] not in RESULTS for t in tests.values()):
        raise ValueError("incomplete Flutter machine report")
    visible = [t for _, t in sorted(tests.items()) if not t["hidden"]]
    if not visible:
        raise ValueError("Flutter machine report contains no visible tests")
    suite = ET.Element("testsuite", name="flutter", tests=str(len(visible)))
    for item in visible:
        case = ET.SubElement(suite, "testcase", name=item["name"], classname=item["suite"])
        if item["result"] in ("failure", "error"):
            ET.SubElement(case, item["result"], message=f"Flutter test {item['result']}").text = (
                "\n\n".join(item["errors"]))
        elif item["skipped"]:
            ET.SubElement(case, "skipped", message=item["skip_reason"])
    destination.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(suite).write(destination, encoding="utf-8", xml_declaration=True)
    return len(visible)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    try:
        print(f"converted={convert(args.source, args.destination)}")
    except (OSError, ValueError, json.JSONDecodeError) as error:
        parser.exit(2, f"invalid Flutter events: {error}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
