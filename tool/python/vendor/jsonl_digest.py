#!/usr/bin/env python3
"""Digest a JSONL log (events, test or agent transcripts, tool traces) instead of reading it whole.

Prints the record count (and unparsable lines), counts per kind (``--key``,
default: the first of ``event``/``type``/``kind``/``method`` present), the
time range (``time``/``timestamp``/``ts``/``created_at``/``at``), records
that look like errors (``level`` error/fatal/critical, a non-empty ``error``,
a ``status``/``conclusion``/``outcome`` of failure/failed/error, or a
JSON-RPC ``result.isError`` of true), and the last ``--last`` records as one
compact line each (``--width`` characters). ``--show N`` prints record N in
full.

``--pairs`` treats the log as JSON-RPC/MCP traffic: it pairs requests with
responses by ``id`` (messages may be the record itself or nested under
``message``/``payload``/``data``/``msg``, as inspector/proxy logs do) and
prints one line per call plus a summary.

``--where FIELD=VALUE`` (repeatable, FIELD may be a dotted path) keeps only
matching records before digesting. ``--count FIELD`` and ``--num FIELD``
(repeatable, dotted paths) print a top-values line, respectively a
n/min/median/mean/max line, for that field. Stdlib only; runs under
``python -S``::

    python -S scripts/jsonl_digest.py run.jsonl
    python -S scripts/jsonl_digest.py session.jsonl --key type --last 5 --show 12
    python -S scripts/jsonl_digest.py mcp-session.jsonl --pairs
    python -S scripts/jsonl_digest.py trace.jsonl --where event=jev/backend_answer --count kind --num answer.noul
    some-command 2>&1 | python -S scripts/jsonl_digest.py -

Exit codes: 0 = digested (even if it contains errors); 1 = no JSON records
(or none match ``--where``); 2 = unreadable input.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from collections import Counter, deque
from datetime import datetime
from pathlib import Path

KIND_KEYS = ("event", "type", "kind", "method")
TIME_KEYS = ("time", "timestamp", "ts", "created_at", "at")
MESSAGE_KEYS = ("message", "payload", "data", "msg")
FAILED = {"failure", "failed", "error", "errored", "interrupted", "blocked", "unavailable"}


def _first(record: dict, keys: tuple[str, ...]) -> tuple[str | None, object]:
    for key in keys:
        if record.get(key) not in (None, ""):
            return key, record[key]
    return None, None


def _get_path(record: object, path: str) -> object:
    """Look up a dotted path (``answer.type``) in nested dicts; None if any step is missing."""
    value: object = record
    for part in path.split("."):
        if isinstance(value, dict) and part in value:
            value = value[part]
        else:
            return None
    return value


def _matches_where(record: object, where: tuple[tuple[str, str], ...]) -> bool:
    return all(str(_get_path(record, field)) == value for field, value in where)


def is_error(record: object) -> bool:
    if not isinstance(record, dict):
        return False
    level = str(record.get("level", "")).lower()
    outcome = {str(record.get(key, "")).lower() for key in ("status", "conclusion", "outcome")}
    result = record.get("result")
    tool_error = isinstance(result, dict) and bool(result.get("isError"))
    return level in {"error", "fatal", "critical"} or bool(record.get("error")) or bool(outcome & FAILED) or tool_error


def compact(index: int, record: object, width: int, key: str | None) -> str:
    if not isinstance(record, dict):
        text = json.dumps(record, ensure_ascii=False, separators=(",", ":"))
        return f"[{index}] {text[:width]}"
    time_key, when = _first(record, TIME_KEYS)
    kind_key, kind = (key, record.get(key)) if key else _first(record, KIND_KEYS)
    rest = {k: v for k, v in record.items() if k not in {time_key, kind_key}}
    text = json.dumps(rest, ensure_ascii=False, separators=(",", ":"))
    if len(text) > width:
        text = text[: max(width - 1, 0)] + "…"
    prefix = " ".join(str(part) for part in (when, f"{kind}:" if kind is not None else None) if part is not None)
    return f"[{index}] {prefix} {text}".replace("  ", " ")


def count_line(dicts: list[dict], field: str) -> str:
    counter: Counter[str] = Counter()
    for record in dicts:
        value = _get_path(record, field)
        counter[str(value) if value is not None else "(missing)"] += 1
    return f"count {field}: " + ", ".join(f"{name} {n}" for name, n in counter.most_common(10))


def _fmt_num(value: float) -> str:
    if value == int(value):
        return str(int(value))
    return f"{value:.4f}".rstrip("0").rstrip(".")


def num_line(dicts: list[dict], field: str) -> str:
    values = sorted(
        number
        for value in (_get_path(record, field) for record in dicts)
        if isinstance(value, (int, float)) and not isinstance(value, bool)
        for number in (float(value),)
        if math.isfinite(number)
    )
    if not values:
        return f"num {field}: (no numeric values)"
    n = len(values)
    mid = n // 2
    median = values[mid] if n % 2 else (values[mid - 1] + values[mid]) / 2
    mean = sum(values) / n
    return (f"num {field}: n={n} min={_fmt_num(values[0])} median={_fmt_num(median)} "
            f"mean={_fmt_num(mean)} max={_fmt_num(values[-1])}")


def _looks_like_rpc(value: object) -> bool:
    if not isinstance(value, dict):
        return False
    if "method" in value:
        return True
    return "id" in value and ("result" in value or "error" in value)


def _rpc_message(record: object) -> dict | None:
    """The JSON-RPC message in a record: the record itself, or nested under a message key."""
    if _looks_like_rpc(record):
        return record  # type: ignore[return-value]
    if isinstance(record, dict):
        for key in MESSAGE_KEYS:
            value = record.get(key)
            if _looks_like_rpc(value):
                return value
    return None


def _id_key(value: object) -> object:
    try:
        hash(value)
        return value
    except TypeError:
        return json.dumps(value, sort_keys=True, default=str)


def _preview_json(value: object, width: int) -> str:
    text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    if len(text) > width:
        text = text[: max(width - 1, 0)] + "…"
    return text


def _call_header(message: dict, width: int) -> str:
    method = message.get("method") or "?"
    params = message.get("params")
    if isinstance(params, dict) and "name" in params:
        return f"{method} name={params['name']} args={_preview_json(params.get('arguments', {}), width)}"
    if params:
        return f"{method} args={_preview_json(params, width)}"
    return str(method)


def _call_outcome(message: dict, width: int) -> tuple[str, str]:
    error = message.get("error")
    result = message.get("result")
    if error is not None:
        return "ERROR", _preview_json(error, width)
    if isinstance(result, dict) and result.get("isError"):
        return "ERROR", _preview_json(result, width)
    return "ok", _preview_json(result, width)


def _parse_iso(value: object) -> datetime | None:
    """Parse an ISO 8601 timestamp that has a trailing Z or a numeric offset; else None."""
    if not isinstance(value, str) or not value.strip():
        return None
    text = value.strip()
    if text[-1] in "Zz":
        text = text[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(text)
    except ValueError:
        return None
    return parsed if parsed.tzinfo is not None else None


def _elapsed(start: object, end: object) -> str | None:
    t0, t1 = _parse_iso(start), _parse_iso(end)
    if t0 is None or t1 is None:
        return None
    seconds = (t1 - t0).total_seconds()
    if seconds == int(seconds):
        return f"{int(seconds)}s"
    return f"{seconds:.3f}".rstrip("0").rstrip(".") + "s"


def pair_calls(records: list[object], width: int) -> list[str]:
    """Pair JSON-RPC requests with the first later unused response of the same id."""
    requests: list[tuple[int, object, dict, str | None]] = []
    pending: dict[object, deque[int]] = {}
    matched: dict[int, tuple[int, dict, str | None]] = {}
    notifications: Counter[str] = Counter()

    for index, record in enumerate(records):
        message = _rpc_message(record)
        if message is None:
            continue
        outer = record if isinstance(record, dict) else {}
        _, when = _first(outer, TIME_KEYS)
        if when is None and message is not outer:
            _, when = _first(message, TIME_KEYS)
        when = str(when) if when is not None else None
        has_id = "id" in message and message.get("id") is not None
        method = message.get("method")

        if method is not None and has_id:
            request_index = len(requests)
            requests.append((index, message.get("id"), message, when))
            pending.setdefault(_id_key(message.get("id")), deque()).append(request_index)
        elif method is not None:
            notifications[method] += 1
        elif has_id and ("result" in message or "error" in message):
            queue = pending.get(_id_key(message.get("id")))
            if queue:
                request_index = queue.popleft()
                matched[request_index] = (index, message, when)

    lines: list[str] = []
    errors = unanswered = 0
    for request_index, (index, _rpc_id, message, when) in enumerate(requests):
        header = _call_header(message, width)
        response = matched.get(request_index)
        if response is None:
            lines.append(f"[{index}] {header} -> no response")
            unanswered += 1
            continue
        r_index, r_message, r_when = response
        status, preview = _call_outcome(r_message, width)
        if status == "ERROR":
            errors += 1
        elapsed = _elapsed(when, r_when)
        suffix = f" ({elapsed})" if elapsed else ""
        lines.append(f"[{index}->{r_index}] {header} -> {status} {preview}{suffix}")

    summary = f"calls: {len(requests)} ({errors} errors, {unanswered} unanswered)"
    if notifications:
        summary += ", notifications: " + ", ".join(f"{name} {n}" for name, n in notifications.items())
    else:
        summary += ", notifications: 0"
    return [summary] + ["  " + line for line in lines]


def digest(lines: list[str], *, source: str, key: str | None = None, last: int = 10, width: int = 160,
           show: tuple[int, ...] = (), pairs: bool = False, where: tuple[tuple[str, str], ...] = (),
           count_fields: tuple[str, ...] = (), num_fields: tuple[str, ...] = ()) -> tuple[str, int]:
    records: list[object] = []
    bad = 0
    for line in lines:
        if not line.strip():
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            bad += 1
    if not records:
        return f"{source}: no JSON records ({bad} unparsable line(s))", 1
    if where:
        matched = [record for record in records if _matches_where(record, where)]
        if not matched:
            return f"{source}: 0 record(s) match --where ({len(records)} total, {bad} unparsable line(s))", 1
        records = matched
    out = [f"{source}: {len(records)} record(s)" + (f" ({bad} unparsable line(s))" if bad else "")]
    dicts = [record for record in records if isinstance(record, dict)]
    times = sorted(str(value) for value in (_first(record, TIME_KEYS)[1] for record in dicts) if value is not None)
    if times:
        out.append(f"time: {times[0]} .. {times[-1]}")
    counts = Counter(str(record.get(key) if key else _first(record, KIND_KEYS)[1]) for record in dicts)
    if counts and set(counts) != {"None"}:
        label = key or "kind"
        out.append(f"by {label}: " + ", ".join(f"{name} {count}" for name, count in counts.most_common(15)))
    for field in count_fields:
        out.append(count_line(dicts, field))
    for field in num_fields:
        out.append(num_line(dicts, field))
    errors = [(index, record) for index, record in enumerate(records) if is_error(record)]
    out.append(f"errors: {len(errors)}")
    out += ["  " + compact(index, record, width, key) for index, record in errors[:10]]
    if len(errors) > 10:
        out.append(f"  [... {len(errors) - 10} more]")
    if last:
        out.append(f"last {min(last, len(records))}:")
        out += ["  " + compact(index, records[index], width, key)
                for index in range(max(len(records) - last, 0), len(records))]
    if pairs:
        out += pair_calls(records, width)
    for index in show:
        if not 0 <= index < len(records):
            return f"{source}: no record {index} (0..{len(records) - 1})", 2
        out += [f"--- [{index}] ---", json.dumps(records[index], ensure_ascii=False, indent=2)]
    return "\n".join(out), 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Digest a JSONL log instead of reading it whole.")
    parser.add_argument("path", help="JSONL file, or - for stdin")
    parser.add_argument("--key", help="field to count by (default: first of event/type/kind/method)")
    parser.add_argument("--last", type=int, default=10, help="compact lines for the last N records (default 10)")
    parser.add_argument("--width", type=int, default=160, help="characters per compact line (default 160)")
    parser.add_argument("--show", default="", help="comma-separated record indexes to print in full")
    parser.add_argument("--pairs", action="store_true",
                        help="pair JSON-RPC requests with responses by id (MCP/LLM test logs)")
    parser.add_argument("--where", action="append", default=[], metavar="FIELD=VALUE",
                        help="keep only records where FIELD (dotted path) equals VALUE, as strings; repeatable")
    parser.add_argument("--count", action="append", default=[], dest="count_fields", metavar="FIELD",
                        help="print the top values of FIELD (dotted path); repeatable")
    parser.add_argument("--num", action="append", default=[], dest="num_fields", metavar="FIELD",
                        help="print n/min/median/mean/max for numeric FIELD (dotted path); repeatable")
    args = parser.parse_args(argv)
    try:
        text = sys.stdin.read() if args.path == "-" else Path(args.path).read_text(encoding="utf-8", errors="replace")
        show = tuple(int(part) for part in args.show.split(",") if part.strip())
        where: list[tuple[str, str]] = []
        for item in args.where:
            if "=" not in item:
                raise ValueError(f"--where must be FIELD=VALUE: {item!r}")
            field, _, value = item.partition("=")
            where.append((field, value))
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    report, code = digest(text.splitlines(), source=args.path, key=args.key, last=args.last, width=args.width,
                          show=show, pairs=args.pairs, where=tuple(where), count_fields=tuple(args.count_fields),
                          num_fields=tuple(args.num_fields))
    print(report, file=sys.stderr if code == 2 else sys.stdout)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
