"""Run one real build and fresh Python/Node controls in that same environment.

No SDK installation, native-build reuse, browser startup or OS impersonation.
The caller supplies a JSON argv; no command text is evaluated by a shell.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import sys

from capture_native_errors import case_manifest, companion_rows, default_seed, invoke

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ("web", "android", "ios", "macos", "windows", "linux")


def capture(root, out, target, command, *, timeout=1800, seed=None):
    root, out = Path(root).resolve(), Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    manifest = case_manifest(root, default_seed() if seed is None else seed)
    manifest_bytes = (json.dumps(manifest, sort_keys=True, ensure_ascii=True, indent=2) + "\n").encode()
    (out / "case-manifest.json").write_bytes(manifest_bytes)
    cases = manifest["cases"]
    started = datetime.now(timezone.utc).isoformat()
    # Retain the actual command/exit/logs; success is never inferred from a
    # previous build or the fact that companion controls passed.
    print("Starting current build; raw output is saved in " + str(out), flush=True)
    build = invoke(command, root, out, "build", timeout=timeout)
    for stream in ("stdout", "stderr"):
        print(build[stream], file=sys.stdout if stream == "stdout" else sys.stderr, end="")
    rows = [{**build, "name": "current-build", "target": target, "input": None,
             "value": build["returncode"], "expected": 0,
             "passed": build["returncode"] == 0 and build["error_type"] is None,
             "error_origin": "target_exit" if build["returncode"] not in (0, None) else None}]
    # These still run after a build failure/timeout, for independent diagnostics.
    rows.extend(companion_rows(root, out, cases))
    commands = {"git": ["git", "rev-parse", "HEAD"],
                "flutter": ["flutter", "--version", "--machine"],
                "doctor": ["flutter", "doctor", "-v"],
                "node": ["node", "--version"]}
    if target in ("ios", "macos"):
        commands.update(xcode=["xcodebuild", "-version"], swift=["xcrun", "swift", "--version"])
    if target == "android":
        commands.update(java=["java", "-version"], gradle=["bash", "android/gradlew", "--version", "-p", "android"])
    metadata = {name: invoke(argv, root, out, "environment-" + name, timeout=60)
                for name, argv in commands.items()}
    sources = ("tools/native_error_corpus/cases.json", "tools/native_error_corpus/array_length.py",
               "tools/native_error_corpus/array_length.mjs", "python/capture_native_errors.py",
               "python/capture_build_companions.py")
    hashes = {}
    for source in sources:
        data = (root / source).read_bytes()
        hashes[source] = hashlib.sha256(data).hexdigest()
        (out / ("source-" + Path(source).name)).write_bytes(data)
    return {"schema": "portable-io-results/1", "scope": "current-build-companions",
            "passed": all(row["passed"] for row in rows), "results": rows,
            "context": {"build_target": target, "build_attempted_current_run": True,
                        "build_executed_current_run": build["returncode"] is not None or build["error_type"] == "TimeoutExpired",
                        "started_at": started, "finished_at": datetime.now(timezone.utc).isoformat(),
                        "run_id": os.environ.get("GITHUB_RUN_ID"),
                        "attempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
                        "job": os.environ.get("GITHUB_JOB"), "metadata": metadata,
                        "metadata_unavailable": [key for key, value in metadata.items()
                                                 if value["returncode"] != 0 or value["error_type"]],
                        "seed": manifest["seed"], "generator_version": manifest["generator_version"],
                        "manifest_sha256": hashlib.sha256(manifest_bytes).hexdigest(),
                        "fixed_case_ids": manifest["fixed_case_ids"],
                        "sampled_case_ids": manifest["sampled_case_ids"],
                        "source_sha256": hashes, "native_app_runtime_verified": False,
                        "unobserved": ["native UI and permissions", "window and display geometry"],
                        "coverage": "fixed and bounded seeded primitive contracts; not the whole application"},
            "collector_environment": {"python": sys.version, "platform": sys.platform,
                                      "system": platform.system(), "release": platform.release(),
                                      "machine": platform.machine()},
            "contract_sha256": hashlib.sha256(json.dumps(cases, sort_keys=True).encode()).hexdigest(),
            "targets": [{"name": target, "argv": command}], "native_equivalence_verified": False}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", choices=TARGETS, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--build-command", required=True, help="JSON argv for one actual build")
    parser.add_argument("--probe-tools", type=Path, help="Pinned xprobe checkout for shared JUnit writer")
    parser.add_argument("--seed", help="Replay manifest; defaults to run ID:attempt")
    args = parser.parse_args(argv)
    try:
        command = json.loads(args.build_command)
        if (not isinstance(command, list) or not command
                or not all(isinstance(arg, str) and arg and "\0" not in arg for arg in command)):
            raise ValueError("build-command must be a nonempty string array")
    except ValueError as error:
        parser.error(str(error))
    result = capture(ROOT, args.output, args.target, command, seed=args.seed)
    result["junit_written"] = False
    receipt = args.output / "receipt.json"
    receipt.write_text(json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")
    # Docker can retain JSON/logs without fetching an extra tool at image build.
    # CI callers supply the same pinned writer as native error acquisition.
    if args.probe_tools:
        sys.path.insert(0, str(args.probe_tools.resolve()))
        from contract_probe import write_junit
        write_junit(result, args.output / "acceptance.xml")
        write_junit(result, args.output / "observed-failures.xml", observations=True)
        result["junit_written"] = True
    receipt.write_text(json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps({"scope": result["scope"], "target": args.target, "passed": result["passed"]}))
    build = result["results"][0]
    # Preserve a positive native build exit; companion failures remain nonzero.
    return build["returncode"] if isinstance(build["returncode"], int) and build["returncode"] > 0 else int(not result["passed"])


if __name__ == "__main__":
    raise SystemExit(main())
