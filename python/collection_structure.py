#!/usr/bin/env python3
"""Generate portable collection structures for display shells."""
from __future__ import annotations
import argparse
import json

ROWS = [
    {"id":"a1","group":"A","label":"Alpha"},
    {"id":"a2","group":"A","label":"Amber"},
    {"id":"b1","group":"B","label":"Beta"},
    {"id":"b2","group":"B","label":"Blue"},
]
TREE = [{"id":"root","label":"Root","children":[
    {"id":"left","label":"Left","children":[]},
    {"id":"right","label":"Right","children":[{"id":"leaf","label":"Leaf","children":[]}]},
]}]

def sections(rows):
    out=[]
    for row in rows:
        if not out or out[-1]["header"] != row["group"]:
            out.append({"header":row["group"],"items":[]})
        out[-1]["items"].append({"id":row["id"],"label":row["label"]})
    return out

def flatten(nodes, depth=0):
    out=[]
    for node in nodes:
        out.append({"id":node["id"],"label":node["label"],"depth":depth})
        out.extend(flatten(node.get("children",[]), depth+1))
    return out

def payload(mode):
    if mode in {"sticky","section","grouped"}:
        values=sections(ROWS)
    elif mode in {"tree","flat"}:
        values=flatten(TREE)
    else:
        raise ValueError("unsupported mode")
    return {"schema":"collection-structure/1","mode":mode,"values":values}

def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--mode",choices=("sticky","section","tree","flat","grouped"),required=True)
    a=p.parse_args(argv)
    print(json.dumps(payload(a.mode),ensure_ascii=False,sort_keys=True))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
