"""Fleet contracts through the parent's shared checks (python/vendor/fleet_check.py): locks and parent pins."""
from vendor import fleet_check as fleet

ROOT = fleet.repo_root(__file__)
PARENT_WORKFLOW_PIN = "9e3da7ae1846e9604ebc24bb5178f7de094a4e77"
ACCEPTED = {"python/vendor/fleet_check.py": "45ed741f7e1f60179934cee6fa1e16a887f97cb0"}


def test_vendor_lock_matches_checked_in_bytes():
    fleet.check_lock(ROOT, "python/vendor.lock.json", commits=ACCEPTED)


def test_parent_workflow_references_use_reviewed_rollout_commit():
    # The .vendor-sync-tools checkout pins the shared vendor tool separately.
    assert set(fleet.parent_refs(ROOT, skip=(".vendor-sync-tools",))) == {PARENT_WORKFLOW_PIN}
