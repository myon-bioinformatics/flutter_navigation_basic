#!/usr/bin/env python3
"""Compare two images (files or zip members) and print one line: size, changed pixels, bbox, max delta.

Pillow is the only dependency (tool/python/requirements.txt). Optional --clip X,Y,W,H in CSS px, scaled by
image width / --viewport-width (screenshots taken at devicePixelRatio != 1).
Source forms: PATH or ZIP::member. Exit 0 = identical (within --tolerance), 1 = differs, 2 = input error.
"""
import argparse, io, sys, zipfile


def load(spec):
    from PIL import Image
    if "::" in spec:
        z, member = spec.split("::", 1)
        with zipfile.ZipFile(z) as archive:
            return Image.open(io.BytesIO(archive.read(member))).convert("RGBA")
    return Image.open(spec).convert("RGBA")


def compare(a, b, clip=None, viewport_width=None, tolerance=0):
    from PIL import ImageChops
    if a.size != b.size:
        return {"size_a": a.size, "size_b": b.size, "same_size": False, "differs": True}
    if clip:
        k = a.width / viewport_width if viewport_width else 1
        x, y, w, h = clip
        box = (round(x * k), round(y * k), round((x + w) * k), round((y + h) * k))
        a, b = a.crop(box), b.crop(box)
    diff = ImageChops.difference(a, b)
    mask = diff.convert("L").point(lambda v: 255 if v > tolerance else 0)
    hist = mask.histogram()
    changed = hist[255]
    total = mask.width * mask.height
    return {"size": a.size, "same_size": True, "changed": changed, "ratio": round(changed / total, 6) if total else 0,
            "bbox": mask.getbbox(), "max_delta": max(hi for lo, hi in diff.getextrema()), "differs": changed > 0}


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("a"); p.add_argument("b")
    p.add_argument("--clip", type=lambda s: tuple(float(v) for v in s.split(",")))
    p.add_argument("--viewport-width", type=float)
    p.add_argument("--tolerance", type=int, default=0)
    args = p.parse_args(argv)
    try:
        result = compare(load(args.a), load(args.b), args.clip, args.viewport_width, args.tolerance)
    except (OSError, KeyError, zipfile.BadZipFile, ImportError) as exc:
        print(f"image_diff: {exc}", file=sys.stderr); return 2
    print(" ".join(f"{k}={v}" for k, v in result.items()))
    return 1 if result["differs"] else 0


if __name__ == "__main__":
    sys.exit(main())
