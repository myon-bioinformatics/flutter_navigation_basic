#!/usr/bin/env python3
"""Evidence-based inventory for all existing data-processing pattern identities.

Source presence and green unit tests do not prove Flutter runtime integration.
stdlib-only, read-only, deterministic, CI-friendly.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
FAKE = ("TODO: 実装を追加してください",
        "await Future.delayed(const Duration(milliseconds: 100));",
        "executed successfully")
PRODUCERS = (
    ((1, 2, 3, 30, 86, 113), "python", "tool/python/list_selection.py", "tool/python/tests/test_list_selection_runtime.py"),
    (range(34, 45), "python", "tool/python/collection_window.py", "tool/python/tests/test_collection_window.py"),
    (range(45, 50), "python", "tool/python/collection_structure.py", "tool/python/tests/test_collection_structure.py"),
    (range(51, 55), "python", "tool/python/collection_window.py", "tool/python/tests/test_collection_window.py"),
    (range(114, 121), "python", "tool/python/collection_transform.py", "tool/python/tests/test_collection_transform.py"),
    (range(121, 127), "javascript", "tool/javascript/future_patterns.mjs", "tool/javascript/tests/future_patterns.test.mjs"),
    (range(127, 136), "javascript", "tool/javascript/stream_patterns.mjs", "tool/javascript/tests/stream_patterns.test.mjs"),
    (range(138, 144), "javascript", "tool/javascript/concurrency_patterns.mjs", "tool/javascript/tests/concurrency_patterns.test.mjs"),
    (range(144, 146), "javascript", "tool/javascript/stream_patterns.mjs", "tool/javascript/tests/event_loop_patterns.test.mjs"),
    (range(146, 151), "javascript", "tool/javascript/event_loop_patterns.mjs", "tool/javascript/tests/event_loop_patterns.test.mjs"),
    (range(164, 166), "python", "tool/python/state_reducer.py", "tool/python/tests/test_state_reducer.py"),
    (range(176, 183), "python", "tool/python/workflow_patterns.py", "tool/python/tests/test_workflow_patterns.py"),
    (range(185, 199), "python", "tool/python/workflow_patterns.py", "tool/python/tests/test_workflow_patterns.py"),
)
NATIVE = set(range(151,164)) | set(range(166,171))
GESTURES = {171, 172, 173, 174, 175, 183, 184}

def pattern_dir(root: Path, number: int) -> Path:
    bucket = "pattern_001_to_099" if number <= 99 else "pattern_100_to_198"
    return root/"lib/features/data_processing_patterns"/bucket/("pattern_%03d" % number)

def producer(number: int) -> dict | None:
    for ids, runtime, source, test in PRODUCERS:
        if number in ids:
            return {"runtime":runtime, "source":source,"test":test,
                    "flutter_runtime_connected":False}
    return None

def responsibility(number: int) -> str:
    if producer(number):
        return producer(number)["runtime"]
    if number in NATIVE or number in GESTURES or number in (136, 137):
        return "flutter_native"
    if number <= 44:
        return "python_processing / flutter_interaction"
    if number <= 60:
        return "python_assets / flutter_layout"
    if number <= 90:
        return "python_cache / runtime_specific"
    if number <= 113:
        return "python_validation / flutter_form"
    return "undecided"

def inspect(root: Path, number: int) -> dict:
    folder = pattern_dir(root,number)
    readme = (folder/"README.md").read_text(encoding="utf-8") if (folder/"README.md").is_file() else ""
    view = (folder/"view.dart").read_text(encoding="utf-8") if (folder/"view.dart").is_file() else ""
    service = (folder/"service.dart").read_text(encoding="utf-8") if (folder/"service.dart").is_file() else ""
    dart = sorted(x.name for x in folder.glob("*.dart"))
    name_match = re.search(r"^# Pattern \d+: (.+)$",readme,re.MULTILINE)
    name = name_match.group(1) if name_match else "unidentified"
    is_fake = bool(service) and all(marker in service for marker in FAKE)
    asset = "ProcessedListExample" in view or "JsonListAsset" in (view+service)
    getx = "package:get/get.dart" in view or "extends GetView" in view
    proof = producer(number)
    if not view or not readme:
        status = "missing_catalogue_artifact"
    elif is_fake:
        status = "fake_delayed_success"
    elif proof:
        status = "standalone_cli_ui_unwired"
    elif asset:
        status = "precomputed_asset_view"
    elif number in NATIVE and not getx:
        status = "native_flutter_example"
    elif getx:
        status = "getx_unreviewed"
    elif dart == ["view.dart"]:
        status = "description_only"
    else:
        status = "needs_manual_review"
    # Match active Dart import/export/part statements, not historical prose.
    active_imports = re.findall(
        r"""(?m)^\s*(?:import|export|part)\s+['"]([^'"]+)['"]\s*;""",
        readme,
    )
    stale = any(
        imported.rsplit("/", 1)[-1] in {"controller.dart", "model.dart", "service.dart"}
        and imported.rsplit("/", 1)[-1] not in dart
        for imported in active_imports
    )
    warnings=[]
    if stale:
        warnings.append("README mentions removed files or old GetX example")
    if status == "fake_delayed_success":
        warnings.append("100ms fabricated success is not real processing")
    if status == "description_only":
        warnings.append("Display text alone has no business function")
    if proof:
        warnings.append("External CLI is not a Flutter execution bridge")
    if number == 102:
        warnings.append("XSS requires contextual encoding; SQL requires parameterized statements")
    if number in (136,137):
        warnings.append("Dart Isolate/compute must be tested in native runtime")
    if number in GESTURES:
        warnings.append("E2E-only direct gesture route is not /screenNNN catalogue screen")
    if number in (187,191,192,195,196,198):
        warnings.append("In-memory reference does not prove durable/distributed service semantics")
    return {"id":number,"name":name,"status":status,"target_owner":responsibility(number),
            "dart_files":dart,"stale_readme":stale,"producer":proof,"warnings":warnings}

def audit(root: Path) -> dict:
    base=root/"lib/features/data_processing_patterns"
    if not base.is_dir():
        raise ValueError("missing pattern catalogue")
    folders = sorted(path for path in base.glob("pattern_*_to_*/pattern_*")
                     if path.is_dir() and re.fullmatch(r"pattern_\d{3}", path.name))
    locations = {}
    for folder in folders:
        number = int(folder.name.removeprefix("pattern_"))
        locations.setdefault(number, []).append(folder)
    numbers = sorted(locations)
    records = [inspect(root, i) for i in numbers]
    expected = set(range(1, 199))
    observed = set(numbers)
    errors = ["%03d: missing catalogue pattern" % i for i in sorted(expected - observed)]
    errors += ["%03d: unexpected catalogue pattern" % i for i in sorted(observed - expected)]
    for number, paths in sorted(locations.items()):
        if len(paths) != 1 or paths[0] != pattern_dir(root, number):
            errors.append("%03d: duplicate or misplaced catalogue directory: %s" %
                          (number, ", ".join(str(p.relative_to(base)) for p in paths)))
    counts=dict(sorted(Counter(item["status"] for item in records).items()))
    for row in records:
        if row["status"] in ("missing_catalogue_artifact", "getx_unreviewed", "needs_manual_review"):
            errors.append("%03d: missing or unclassified implementation evidence" % row["id"])
        if row["producer"]:
            for field in ("source","test"):
                source=row["producer"][field]
                if not (root/source).is_file():
                    errors.append("%03d: missing %s %s" % (row["id"],field,source))
    return {"schema":"pattern-responsibility/1",
            "summary":{"patterns":len(records),
                       "dart_files":sum(len(x["dart_files"]) for x in records),
                       "statuses":counts,
                       "stale_readmes":sum(x["stale_readme"] for x in records),
                       "errors":len(errors)},
            "errors":errors,"patterns":records}

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,default=ROOT)
    parser.add_argument("--json",action="store_true")
    parser.add_argument("--check",action="store_true")
    args=parser.parse_args(argv)
    try:
        result=audit(args.root.resolve())
    except (ValueError,OSError) as error:
        print("audit: "+str(error),file=sys.stderr)
        return 2
    print(json.dumps(result if args.json else result["summary"],ensure_ascii=False,sort_keys=True,indent=2))
    return 1 if args.check and result["errors"] else 0

if __name__=="__main__":
    raise SystemExit(main())
