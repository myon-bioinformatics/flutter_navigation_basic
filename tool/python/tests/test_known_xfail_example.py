"""Documented known/xfail examples so outcome tallies exercise the full mix."""

from __future__ import annotations

import pytest


@pytest.mark.xfail(
    reason="known: example expected-fail for outcomes receipt (do not remove)",
    run=False,
    strict=True,
)
def test_known_xfail_example_for_outcomes_receipt() -> None:
    """Always xfail (not run) so CI receipts show an xfailed count > 0."""
    raise AssertionError("unreachable: xfail run=False")
