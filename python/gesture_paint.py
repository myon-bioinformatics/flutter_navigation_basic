"""Check a same-run A/B card swap in saved PNGs, not the semantics DOM.

This is an evidence oracle, not a browser runner. It reuses the locked stdlib
image backend. Exact card interiors must exchange places; stable stale frames
and blank/identical reference cards cannot pass. No pixel tolerance is applied.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import sys

from image_diff import compare, load


def check_swap(before, after, geometry):
    if before.size != after.size:
        raise ValueError("capture dimensions changed during the gesture")
    scale = geometry["device_scale_factor"]
    if not isinstance(scale, (int, float)) or not math.isfinite(scale) or scale <= 0:
        raise ValueError("invalid device scale factor")
    viewport = geometry["viewport"]
    if any(abs(before.size[i] - viewport[key] * scale) > 1
           for i, key in enumerate(("width", "height"))):
        raise ValueError("PNG dimensions do not match the recorded viewport")
    slots = geometry["slots"]
    if len(slots) != 2:
        raise ValueError("exactly two pre-drag slots are required")
    crops = []
    for slot in slots:
        x, y, width, height = (slot[key] for key in ("x", "y", "width", "height"))
        if not all(isinstance(v, (int, float)) and math.isfinite(v)
                   for v in (x, y, width, height)):
            raise ValueError("invalid card bounds")
        # Exclude the card's outer shadow/rounded edge, not its label or content.
        if width <= 16 or height <= 16:
            raise ValueError("card interior is too small")
        box = tuple(round(v * scale) for v in
                    (x + 8, y + 8, x + width - 8, y + height - 8))
        if box[0] < 0 or box[1] < 0 or box[2] > before.width or box[3] > before.height:
            raise ValueError("card crop is outside the PNG")
        if box[2] <= box[0] or box[3] <= box[1]:
            raise ValueError("card crop is empty")
        crops.append(box)
    reference = [before.crop(box) for box in crops]
    if reference[0].size != reference[1].size:
        raise ValueError("the two card interiors have different pixel dimensions")
    if not compare(*reference)["differs"]:
        raise ValueError("reference card interiors are identical, possibly blank")
    comparisons = [compare(reference[1 - index], after.crop(box))
                   for index, box in enumerate(crops)]
    return {"matches": all(not result["differs"] for result in comparisons),
            "pixel_crops": crops, "comparisons": comparisons}


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 3:
        print("usage: gesture_paint.py BEFORE.png AFTER.png GEOMETRY.json", file=sys.stderr)
        return 2
    try:
        result = check_swap(load(args[0]), load(args[1]), json.loads(Path(args[2]).read_text()))
    except (ValueError, KeyError, TypeError, OSError) as error:
        print(json.dumps({"error": str(error)}))
        return 2
    print(json.dumps(result))
    return 0 if result["matches"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
