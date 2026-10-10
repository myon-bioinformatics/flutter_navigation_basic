#!/usr/bin/env python3
"""Convert Flutter machine JSON test events into per-case JUnit XML (stdlib)."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def convert(source: Path, destination: Path) -> int:
    tests: dict[int, dict] = {}
    done = False
    for line in source.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        event = json.loads(line)
        if not isinstance(event, dict):
            raise ValueError("invalid Flutter event")
        kind = event.get("type")
        if kind == "testStart":
            test = event.get("test", {})
            identifier = test.get("id")
            if type(identifier) is not int or identifier in tests:
                raise ValueError("duplicate or missing Flutter test ID")
            tests[identifier] = {"name": str(test.get("name", "")), "result": None, "errors": []}
        elif kind == "error":
            identifier = event.get("testID")
            if identifier not in tests:
                raise ValueError("orphan Flutter error")
            tests[identifier]["errors"].append(str(event.get("error", "test error")))
        elif kind == "testDone":
            identifier = event.get("testID")
            if identifier not in tests or tests[identifier]["result"] is not None:
                raise ValueError("orphan or duplicate Flutter completion")
            tests[identifier]["result"] = event.get("result")
        elif kind == "done":
            done = True
    if not done or not tests or any(not t["name"] or t["result"] not in
                                    ("success", "failure", "error", "skipped") for t in tests.values()):
        raise ValueError("incomplete Flutter machine report")
    suite = ET.Element("testsuite", name="flutter", tests=str(len(tests)))
    for identifier, item in sorted(tests.items()):
        case = ET.SubElement(suite, "testcase", name=item["name"], classname="flutter")
        if item["result"] in ("failure", "error"):
            tag = "error" if item["result"] == "error" else "failure"
            ET.SubElement(case, tag, message="Flutter test failed").text = "\n".join(item["errors"])
        elif item["result"] == "skipped":
            ET.SubElement(case, "skipped")
    destination.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(suite).write(destination, encoding="utf-8", xml_declaration=True)
    return len(tests)


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
