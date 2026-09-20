"""Unit tests for the pure-logic parts of tool/python/net_probe.py.

Mirrors tool/net_probe.dart, which also has no test coverage today --
what's actually testable without a live network is formatting and input
validation; the DNS/TCP/TLS/HTTP probing itself is a manual diagnostic
tool in both languages.
"""

from __future__ import annotations

import sys
from pathlib import Path

_HERE = Path(__file__).resolve().parent
_PYTHON_DIR = _HERE.parent
if str(_PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(_PYTHON_DIR))

import net_probe  # noqa: E402


def test_format_duration_sub_second_is_milliseconds() -> None:
    assert net_probe._format_duration(0.005) == "5 ms"
    assert net_probe._format_duration(0.999) == "999 ms"


def test_format_duration_one_second_or_more_is_seconds() -> None:
    assert net_probe._format_duration(1.0) == "1.0s"
    assert net_probe._format_duration(2.5) == "2.5s"


def test_format_bytes_scales_units() -> None:
    assert net_probe._format_bytes(0) == "0 B"
    assert net_probe._format_bytes(999) == "999 B"
    assert net_probe._format_bytes(1024) == "1.00 KiB"
    assert net_probe._format_bytes(1536) == "1.50 KiB"
    assert net_probe._format_bytes(1024 * 1024) == "1.00 MiB"
    assert net_probe._format_bytes(1024 * 1024 * 1024) == "1.00 GiB"


def test_format_name_joins_rdn_components() -> None:
    rdns = ((("commonName", "example.com"),), (("organizationName", "Example Co"),))
    assert net_probe._format_name(rdns) == "commonName=example.com, organizationName=Example Co"
    assert net_probe._format_name(()) == ""


def test_run_rejects_url_without_scheme() -> None:
    assert net_probe.run("not a url") == 64


def test_run_rejects_unsupported_scheme() -> None:
    assert net_probe.run("ftp://example.com") == 64


def test_main_with_no_args_prints_usage_and_exits_zero() -> None:
    assert net_probe.main([]) == 0


def test_main_with_help_flag_exits_zero() -> None:
    assert net_probe.main(["--help"]) == 0
    assert net_probe.main(["-h"]) == 0
