#!/usr/bin/env python3
"""Evidence-based inventory for all existing data-processing pattern identities.

Source presence and green unit tests do not prove Flutter runtime integration.
stdlib-only, read-only, deterministic, CI-friendly.
"""
from __future__ import annotations

import argparse
import hashlib
from collections import Counter
import json
from pathlib import Path
import re
import sys
import tomllib

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_route_observations import known_widgets  # noqa: E402  single source of widget kinds

ROOT = Path(__file__).resolve().parents[2]
FAKE = ("TODO: 実装を追加してください",
        "await Future.delayed(const Duration(milliseconds: 100));",
        "executed successfully")
PRODUCERS = (
    ((103, 104, 105, 107, 109, 110), "python", "tool/python/conversion_patterns.py", "tool/python/tests/test_conversion_patterns.py"),
    (range(91, 100), "python", "tool/python/validation_patterns.py", "tool/python/tests/test_validation_patterns.py"),
    ((4, 35), "javascript", "tool/javascript/interaction_patterns.mjs", "tool/javascript/tests/interaction_patterns.test.mjs"),
    ((25, 28), "python", "tool/python/scoring_heap_patterns.py", "tool/python/tests/test_scoring_heap_patterns.py"),
    ((6, 7, 8, 21, 22, 23), "python", "tool/python/search_patterns.py", "tool/python/tests/test_search_patterns.py"),
    ((11, 12, 14, 15, 16, 17, 18), "python", "tool/python/collection_query_patterns.py", "tool/python/tests/test_collection_query_patterns.py"),
    ((31, 32, 33), "python", "tool/python/pagination_patterns.py", "tool/python/tests/test_pagination_patterns.py"),
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
MANIFEST = "tool/ci/numbered_routes.toml"
# Provision = what the app really shows on /screenNNN. The hand-written TOML is
# checked against runtime observations (numbered_routes_observation_test.dart
# + check_route_observations.py) in CI, so it is evidence, not a guess.
PROVISION = {
    "InteractivePatternExample": "shared_interaction",
    "NativeParallelPatternExample": "shared_native_example",
    "ValidationPatternLinks": "shared_source_links",
    "ConversionPatternLinks": "shared_source_links",
    "GenericScreen": "generic_catalogue",
    "Screen5Page": "dedicated_feature_page",
}

def load_routes(root: Path) -> tuple[dict[int, str], dict[str, set[str]], list[str]]:
    """Read the hand-written route expectations; return (id -> widget, kinds, errors)."""
    path = root/MANIFEST
    if not path.is_file():
        return {}, {}, [f"{MANIFEST}: missing"]
    try:
        doc = tomllib.loads(path.read_text(encoding="utf-8"))
        shared, generic = set(doc["shared_widgets"]), doc["generic_widget"]
        dedicated = set(doc.get("dedicated_widgets", {}))
        routes = doc["routes"]
    except (ValueError, KeyError, TypeError) as error:
        return {}, {}, [f"{MANIFEST}: unreadable ({type(error).__name__})"]
    errors = []
    if doc.get("schema") != "numbered-routes/1":
        errors.append(f"{MANIFEST}: unexpected schema")
    if list(routes) != ["%03d" % i for i in range(1, 199)]:
        errors.append(f"{MANIFEST}: must list 001-198 in order")
    known = known_widgets(doc)
    unknown = sorted({w for w in routes.values() if w not in known} | known - set(PROVISION))
    if unknown:
        errors.append(f"{MANIFEST}: unknown widget kinds {unknown}")
    parsed = {int(k): v for k, v in routes.items() if k.isdigit()}
    return parsed, {"shared": shared, "dedicated": dedicated, "generic": {generic}}, errors

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

def inspect(root: Path, number: int, routes: dict[int, str] | None = None,
            kinds: dict[str, set[str]] | None = None) -> dict:
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
    if routes is None:
        routes, kinds, _ = load_routes(root)
    route = routes.get(number)
    kinds = kinds or {}
    reachability = ("shared" if route in kinds.get("shared", ()) else
                    "dedicated" if route in kinds.get("dedicated", ()) else
                    "generic" if route in kinds.get("generic", ()) else "unknown")
    # Public code may not import *_patterns (test_pattern_catalogue_boundary), so a
    # pattern view.dart is never reachable from the app; count it as legacy.
    legacy_view = "unreachable" if view else "absent"
    if not readme or (not view and reachability != "shared"):
        status = "missing_catalogue_artifact"
    elif is_fake:
        status = "fake_delayed_success"
    elif proof:
        status = "standalone_cli_ui_unwired"
    elif asset:
        status = "precomputed_asset_view"
    elif number in GESTURES and not getx and route == "InteractivePatternExample":
        status = "native_flutter_shared_interaction"
    elif number in NATIVE and not getx:
        status = "native_flutter_example"
    elif getx:
        status = "getx_unreviewed"
    elif not view:
        status = "shared_widget_route"
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
    if number in GESTURES and status != "native_flutter_shared_interaction":
        warnings.append("Numbered route does not build the shared native interaction")
    elif number in GESTURES:
        warnings.append("Numbered route proven by the Flutter manifest test; verify browser gestures separately")
    if number in (187,191,192,195,196,198):
        warnings.append("In-memory reference does not prove durable/distributed service semantics")
    return {"id":number,"name":name,"status":status,"target_owner":responsibility(number),
            "route":route,"reachability":reachability,
            "provision":PROVISION.get(route, "unknown"),"legacy_view":legacy_view,
            "dart_files":dart,"stale_readme":stale,"producer":proof,"warnings":warnings}

def audit(root: Path, verification: dict | None = None) -> dict:
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
    routes, kinds, route_errors = load_routes(root)
    records = [inspect(root, i, routes, kinds) for i in numbers]
    expected = set(range(1, 199))
    observed = set(numbers)
    errors = ["%03d: missing catalogue pattern" % i for i in sorted(expected - observed)]
    errors += ["%03d: unexpected catalogue pattern" % i for i in sorted(observed - expected)]
    errors += route_errors
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
            # Explicit status instead of null: a report without a receipt is unverified.
            "route_verification": ({"status": "verified", **verification} if verification
                                   else {"status": "unverified"}),
            "summary":{"patterns":len(records),
                       "dart_files":sum(len(x["dart_files"]) for x in records),
                       "statuses":counts,
                       "provisions":dict(sorted(Counter(x["provision"] for x in records).items())),
                       "reachability":dict(sorted(Counter(x["reachability"] for x in records).items())),
                       "legacy_views":dict(sorted(Counter(x["legacy_view"] for x in records).items())),
                       "stale_readmes":sum(x["stale_readme"] for x in records),
                       "errors":len(errors)},
            "errors":errors,"patterns":records}

def verify_receipt(root: Path, path: Path, head_sha: str | None, run_id: str | None) -> dict:
    """Accept a route receipt only for this head, this run and the current TOML bytes."""
    receipt = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(receipt, dict) or receipt.get("schema") != "route-verification/1" \
            or receipt.get("result") != "success":
        raise ValueError("invalid route verification receipt")
    if not head_sha or not run_id:
        raise ValueError("route verification requires expected head SHA and run ID")
    if receipt.get("head_sha") != head_sha:
        raise ValueError("route verification head SHA does not match expected head")
    if receipt.get("run_id") != run_id:
        raise ValueError("route verification run ID does not match expected run")
    if receipt.get("routes") != 198:
        raise ValueError("route verification receipt does not cover 198 routes")
    if receipt.get("expected_sha256") != hashlib.sha256((root/MANIFEST).read_bytes()).hexdigest():
        raise ValueError(f"route verification was made against a different {MANIFEST}")
    return receipt

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,default=ROOT)
    parser.add_argument("--json",action="store_true")
    parser.add_argument("--check",action="store_true")
    parser.add_argument("--route-verification",type=Path)
    parser.add_argument("--route-head-sha")
    parser.add_argument("--route-run-id")
    args=parser.parse_args(argv)
    try:
        verification = None
        if args.route_verification:
            verification = verify_receipt(args.root.resolve(), args.route_verification,
                                          args.route_head_sha, args.route_run_id)
        result=audit(args.root.resolve(), verification)
    except (ValueError,OSError) as error:
        print("audit: "+str(error),file=sys.stderr)
        return 2
    print(json.dumps(result if args.json else result["summary"],ensure_ascii=False,sort_keys=True,indent=2))
    return 1 if args.check and result["errors"] else 0

if __name__=="__main__":
    raise SystemExit(main())
