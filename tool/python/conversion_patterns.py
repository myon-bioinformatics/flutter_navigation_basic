#!/usr/bin/env python3
"""Pure stdlib data conversion contracts for patterns 103-105, 107, 109-110."""
from __future__ import annotations
from datetime import date
import base64
import json
import math
import re
import sys
import unicodedata

# ASCII-only decimal/scientific notation. float() alone would also accept
# underscores ("1_000"), surrounding spaces and non-ASCII digits ("١٢").
_FLOAT = re.compile(r"[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?")
_ISO_DATE = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")


def run(req):
    if not isinstance(req, dict):
        raise ValueError("request must be object")
    op = req.get("operation")
    value = req.get("value")
    if op == "normalize":
        if not isinstance(value, str):
            raise ValueError("normalize expects string")
        form = req.get("form", "NFKC")
        if form not in ("NFC", "NFKC"):
            raise ValueError("unsupported normalization form")
        result = unicodedata.normalize(form, value.strip())
        case = req.get("case", "preserve")
        if case == "lower":
            result = result.casefold()
        elif case == "upper":
            result = result.upper()
        elif case != "preserve":
            raise ValueError("unsupported case mode")
        return {"value": result}
    if op == "coerce":
        target = req.get("target")
        if target == "int":
            if isinstance(value, bool) or not isinstance(value, (str, int)):
                raise ValueError("unsafe integer coercion")
            text = str(value)
            if not re.fullmatch(r"[+-]?[0-9]+", text):
                raise ValueError("invalid integer")
            return {"value": int(text)}
        if target == "float":
            if isinstance(value, bool) or not isinstance(value, (str, int, float)):
                raise ValueError("unsafe float coercion")
            if isinstance(value, str) and not _FLOAT.fullmatch(value):
                raise ValueError("invalid float")
            try:
                result = float(value)
            except (ValueError, OverflowError) as exc:
                raise ValueError("invalid float") from exc
            if not math.isfinite(result):
                raise ValueError("non-finite float")
            return {"value": result}
        if target == "bool":
            # Exact types only: 1.0 == 1 and must not count as a boolean.
            if value is True or value in ("true", "1") or (type(value) is int and value == 1):
                return {"value": True}
            if value is False or value in ("false", "0") or (type(value) is int and value == 0):
                return {"value": False}
            raise ValueError("invalid boolean")
        raise ValueError("unsupported target")
    if op == "date":
        if not isinstance(value, str):
            raise ValueError("date expects string")
        source = req.get("source", "iso")
        if source == "iso":
            # fromisoformat also takes week dates and YYYYMMDD; keep YYYY-MM-DD.
            if not _ISO_DATE.fullmatch(value):
                raise ValueError("invalid iso date")
            parsed = date.fromisoformat(value)
        elif source == "compact":
            if not re.fullmatch(r"[0-9]{8}", value):
                raise ValueError("invalid compact date")
            parsed = date(int(value[:4]), int(value[4:6]), int(value[6:]))
        else:
            raise ValueError("unsupported date format")
        target = req.get("target", "iso")
        if target == "iso":
            out = parsed.isoformat()
        elif target == "compact":
            # strftime("%Y") is not zero-padded below year 1000 on glibc.
            out = f"{parsed.year:04d}{parsed.month:02d}{parsed.day:02d}"
        else:
            raise ValueError("unsupported target format")
        return {"value": out}
    if op == "unit":
        unit_from, unit_to = req.get("from"), req.get("to")
        if type(value) not in (int, float) or not math.isfinite(value):
            raise ValueError("unit value must be finite number")
        factors = {"m": 1.0, "km": 1000.0, "cm": 0.01, "kg": 1.0, "g": 0.001}
        groups = [{"m", "km", "cm"}, {"kg", "g"}]
        if unit_from not in factors or unit_to not in factors or not any({unit_from, unit_to} <= g for g in groups):
            raise ValueError("incompatible units")
        result = value * factors[unit_from] / factors[unit_to]
        if not math.isfinite(result):
            raise ValueError("unit conversion overflow")
        return {"value": result}
    if op == "encoding":
        if not isinstance(value, str):
            raise ValueError("encoding expects string")
        mode = req.get("mode")
        if mode == "utf8_to_base64":
            return {"value": base64.b64encode(value.encode("utf-8")).decode("ascii")}
        if mode == "base64_to_utf8":
            try:
                raw = base64.b64decode(value, validate=True)
                return {"value": raw.decode("utf-8")}
            except (ValueError, UnicodeError) as exc:
                raise ValueError("invalid base64 utf8") from exc
        raise ValueError("unsupported encoding mode")
    if op == "mask":
        if not isinstance(value, str):
            raise ValueError("mask expects string")
        keep = req.get("keep_last", 4)
        if type(keep) is not int or not 0 <= keep <= 32:
            raise ValueError("invalid keep_last")
        if len(value) <= keep:  # never reveal a value shorter than the suffix
            return {"value": "*" * len(value)}
        return {"value": "*" * (len(value) - keep) + (value[-keep:] if keep else "")}
    raise ValueError("unsupported operation")


def main():
    try:
        raw = sys.stdin.read(1_000_001)
        if len(raw) > 1_000_000:
            raise ValueError("input too large")
        print(json.dumps(run(json.loads(raw)), ensure_ascii=False, allow_nan=False))
    except (ValueError, TypeError, OverflowError) as exc:
        print(f"invalid conversion request: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
