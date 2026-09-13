#!/usr/bin/env python3
"""Report-only web build artifact size summary (stdlib only).

Produces JSON with file counts, byte totals, category/extension breakdowns,
largest files, and a gzip estimate. Optional before/after delta compare.
Does not enforce budgets and does not require dual CI builds.

Distinct from ``tool/build_meta.dart`` / ``tool/inspect.dart``.
"""

from __future__ import annotations

import argparse
import gzip
import json
import sys
from pathlib import Path
from typing import Any

ASSET_EXTENSIONS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".svg",
    ".ico",
    ".woff",
    ".woff2",
    ".ttf",
    ".otf",
    ".eot",
    ".mp3",
    ".wav",
    ".ogg",
    ".mp4",
    ".webm",
    ".json",
    ".txt",
    ".xml",
    ".html",
    ".css",
    ".map",
}


def categorize(path: Path) -> str:
    ext = path.suffix.lower()
    if ext == ".js":
        return "js"
    if ext == ".wasm":
        return "wasm"
    if ext in ASSET_EXTENSIONS:
        return "assets"
    return "other"


def gzip_size(data: bytes) -> int:
    return len(gzip.compress(data, compresslevel=6))


def scan_root(root: Path, *, largest_n: int = 20) -> dict[str, Any]:
    if not root.is_dir():
        raise FileNotFoundError(f"root is not a directory: {root}")

    files: list[dict[str, Any]] = []
    by_extension: dict[str, dict[str, int]] = {}
    by_category: dict[str, dict[str, int]] = {
        "js": {"count": 0, "bytes": 0},
        "wasm": {"count": 0, "bytes": 0},
        "assets": {"count": 0, "bytes": 0},
        "other": {"count": 0, "bytes": 0},
    }
    total_bytes = 0
    gzip_total = 0

    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        data = path.read_bytes()
        size = len(data)
        rel = path.relative_to(root).as_posix()
        ext = path.suffix.lower() or "(none)"
        category = categorize(path)
        gz = gzip_size(data)

        total_bytes += size
        gzip_total += gz
        by_category[category]["count"] += 1
        by_category[category]["bytes"] += size
        bucket = by_extension.setdefault(ext, {"count": 0, "bytes": 0})
        bucket["count"] += 1
        bucket["bytes"] += size
        files.append(
            {
                "path": rel,
                "bytes": size,
                "gzip_bytes": gz,
                "extension": ext,
                "category": category,
            }
        )

    largest = sorted(files, key=lambda row: (-row["bytes"], row["path"]))[:largest_n]
    return {
        "schema_version": 1,
        "kind": "build_artifact_report",
        "root": root.as_posix(),
        "file_count": len(files),
        "total_bytes": total_bytes,
        "gzip_estimate_bytes": gzip_total,
        "by_category": by_category,
        "by_extension": dict(sorted(by_extension.items())),
        "largest_files": largest,
    }


def _bucket_delta(
    before: dict[str, dict[str, int]], after: dict[str, dict[str, int]]
) -> dict[str, dict[str, int]]:
    keys = sorted(set(before) | set(after))
    out: dict[str, dict[str, int]] = {}
    for key in keys:
        b = before.get(key, {"count": 0, "bytes": 0})
        a = after.get(key, {"count": 0, "bytes": 0})
        out[key] = {
            "count": a.get("count", 0) - b.get("count", 0),
            "bytes": a.get("bytes", 0) - b.get("bytes", 0),
        }
    return out


def compare_reports(before: dict[str, Any], after: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "kind": "build_artifact_compare",
        "before_root": before.get("root"),
        "after_root": after.get("root"),
        "file_count": {
            "before": before.get("file_count", 0),
            "after": after.get("file_count", 0),
            "delta": after.get("file_count", 0) - before.get("file_count", 0),
        },
        "total_bytes": {
            "before": before.get("total_bytes", 0),
            "after": after.get("total_bytes", 0),
            "delta": after.get("total_bytes", 0) - before.get("total_bytes", 0),
        },
        "gzip_estimate_bytes": {
            "before": before.get("gzip_estimate_bytes", 0),
            "after": after.get("gzip_estimate_bytes", 0),
            "delta": after.get("gzip_estimate_bytes", 0)
            - before.get("gzip_estimate_bytes", 0),
        },
        "by_category": _bucket_delta(
            before.get("by_category") or {}, after.get("by_category") or {}
        ),
        "by_extension": _bucket_delta(
            before.get("by_extension") or {}, after.get("by_extension") or {}
        ),
    }


def _load_json(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"expected JSON object in {path}")
    return payload


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Report-only web artifact size summary (stdlib). "
            "No hard budgets; optional before/after JSON compare."
        )
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--root",
        type=Path,
        help="Directory to scan (for example build/web)",
    )
    mode.add_argument(
        "--compare",
        nargs=2,
        metavar=("BEFORE_JSON", "AFTER_JSON"),
        help="Compare two previously written report JSON files",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Write JSON report to this path (also printed to stdout)",
    )
    parser.add_argument(
        "--largest",
        type=int,
        default=20,
        help="How many largest files to include (default: 20)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.compare is not None:
        before_path, after_path = (Path(p) for p in args.compare)
        report = compare_reports(_load_json(before_path), _load_json(after_path))
    else:
        report = scan_root(args.root.resolve(), largest_n=max(0, args.largest))

    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output is not None:
        _write_json(args.output, report)
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
