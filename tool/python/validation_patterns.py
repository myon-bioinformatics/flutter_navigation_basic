#!/usr/bin/env python3
"""Small, deterministic validation contracts for patterns 091-099.

Not a security-grade email/phone/password verifier. Regex validation uses a
fixed allowlist of safe named patterns, never user-provided regular expressions.
"""
from __future__ import annotations

from datetime import date
import json
import math
import re
import sys
from urllib.parse import urlsplit

NAMED_PATTERNS = {
    "ascii_identifier": r"[A-Za-z_][A-Za-z_0-9]*",
    "hex_color": r"#[0-9a-fA-F]{6}",
    "digits": r"[0-9]+",
}


def _number(value) -> bool:
    """JSON number check without float conversion: huge ints are exact, not errors."""
    return type(value) is int or (type(value) is float and math.isfinite(value))


def validate(operation: str, value, options=None):
    options = options or {}
    if not isinstance(options, dict):
        raise ValueError("options must be an object")
    if operation == "required":
        return value is not None and (not isinstance(value, str) or bool(value.strip()))
    if operation == "email":
        return isinstance(value, str) and len(value) <= 254 and bool(re.fullmatch(
            r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", value))
    if operation == "password":
        # Heuristic only; never claim resistance to leaked/common passwords.
        return isinstance(value, str) and len(value) >= 12 and len(value) <= 1024 and any(
            c.isalpha() for c in value) and any(c.isdigit() for c in value)
    if operation == "phone":
        return isinstance(value, str) and bool(re.fullmatch(r"\+?[0-9]{8,15}", value))
    if operation == "url":
        if not isinstance(value, str) or len(value) > 2048 or any(c.isspace() for c in value):
            return False
        try:
            parts = urlsplit(value)
            return parts.scheme in ("http", "https") and bool(parts.hostname) and not parts.username and not parts.password and parts.port != 0
        except ValueError:
            return False
    if operation == "date":
        if not isinstance(value, str) or not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", value):
            return False
        try:
            return date.fromisoformat(value).isoformat() == value
        except ValueError:
            return False
    if operation == "range":
        low, high = options.get("minimum"), options.get("maximum")
        if not (_number(low) and _number(high)) or low > high:
            raise ValueError("invalid numeric range")
        return _number(value) and low <= value <= high
    if operation == "regex":
        name = options.get("pattern")
        if name not in NAMED_PATTERNS:
            raise ValueError("unknown named regex")
        return isinstance(value, str) and len(value) <= 4096 and bool(re.fullmatch(NAMED_PATTERNS[name], value))
    raise ValueError("unsupported validation operation")


def run(request):
    if not isinstance(request, dict):
        raise ValueError("request must be an object")
    operation = request.get("operation")
    if operation == "form":
        fields = request.get("fields")
        if not isinstance(fields, list) or not fields:
            raise ValueError("form requires fields")
        results = []
        for field in fields:
            if not isinstance(field, dict) or not isinstance(field.get("name"), str) or not field["name"]:
                raise ValueError("invalid form field")
            results.append({"name": field["name"], "valid": validate(field.get("rule"), field.get("value"), field.get("options"))})
        return {"valid": all(r["valid"] for r in results), "fields": results}
    return {"valid": validate(operation, request.get("value"), request.get("options"))}


def main():
    try:
        raw = sys.stdin.read(2_000_001)
        if len(raw) > 2_000_000:
            raise ValueError("input too large")
        print(json.dumps(run(json.loads(raw)), ensure_ascii=False))
    except (ValueError, TypeError) as exc:
        print(f"invalid validation request: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
