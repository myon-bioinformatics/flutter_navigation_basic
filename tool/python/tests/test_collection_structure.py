import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[3]
SCRIPT=ROOT/"tool/python/collection_structure.py"
spec=importlib.util.spec_from_file_location("collection_structure",SCRIPT)
module=importlib.util.module_from_spec(spec); assert spec.loader; spec.loader.exec_module(module)

def test_sections_are_deterministic():
    values=module.payload("section")["values"]
    assert [x["header"] for x in values]==["A","B"]
    assert [x["id"] for x in values[0]["items"]]==["a1","a2"]

def test_tree_flatten_preserves_depth_and_order():
    values=module.payload("flat")["values"]
    assert [(x["id"],x["depth"]) for x in values]==[("root",0),("left",1),("right",1),("leaf",2)]

def test_cli_is_flutter_independent():
    result=subprocess.run([sys.executable,"-I","-S",str(SCRIPT),"--mode","grouped"],capture_output=True,text=True,timeout=5)
    assert result.returncode==0
    payload=json.loads(result.stdout)
    assert payload["schema"]=="collection-structure/1"
    assert len(payload["values"])==2
