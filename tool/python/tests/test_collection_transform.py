"""Contract tests for stdlib producer used by catalogue 114-120."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "collection_transform.py"
spec = importlib.util.spec_from_file_location("collection_transform", SCRIPT)
producer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(producer)


@pytest.mark.parametrize(("payload", "expected"), [
    ({"operation":"schema_validation","values":[{"id":1},{"id":"x"},{}],
      "schema":{"type":"object","properties":{"id":{"type":"integer"}},"required":["id"]}},
     [True,False,False]),
    ({"operation":"constraint","values":[2,5,10],"condition":{"operator":"greater_than","value":4}},
     [False,True,True]),
    ({"operation":"pipeline","values":[" A "," B "],"steps":[{"operation":"strip"},{"operation":"lower"}]},
     ["a","b"]),
    ({"operation":"pipeline","values":[1,2],"steps":[{"operation":"multiply","value":2},{"operation":"add","value":1}]},
     [3,5]),
    ({"operation":"map_reduce","values":[{"group":"a"},{"group":"b"},{"group":"a"}],
      "key":"group","reducer":"count"}, [{"key":"a","value":2},{"key":"b","value":1}]),
    ({"operation":"map_reduce","values":[{"group":"a","value":3},{"group":"a","value":2}],
      "key":"group","reducer":"sum"}, [{"key":"a","value":5}]),
    ({"operation":"flatten","values":[[1,[2]],3,[]]}, [1,2,3]),
    ({"operation":"partition","values":[1,2,3],"condition":{"operator":"greater_than","value":1}},
     {"matched":[2,3],"unmatched":[1]}),
    ({"operation":"zip","values":[1,2,3],"other":["a","b"]}, [[1,"a"],[2,"b"]]),
])
def test_real_operations(payload, expected):
    actual = producer.process(payload)
    assert actual["schema"] == "collection-transform/1"
    assert actual["operation"] == payload["operation"]
    assert actual["values"] == expected


@pytest.mark.parametrize("payload", [
    {}, {"operation":"unknown","values":[]},
    {"operation":"flatten","values":{}},
    {"operation":"zip","values":[1],"other":[],"strict":True},
    {"operation":"zip","values":[1],"other":[2],"strict":"false"},
    {"operation":"schema_validation","values":[1],"schema":{"type":"wrong"}},
    {"operation":"schema_validation","values":[{}],"schema":{"type":"object","properties":{"x":{"type":"wrong"}}}},
    {"operation":"constraint","values":[1],"condition":{"operator":"greater_than","value":"x"}},
    {"operation":"partition","values":[1],"condition":{"operator":"unknown"}},
    {"operation":"pipeline","values":["a"],"steps":[{"operation":"multiply","value":2}]},
    {"operation":"map_reduce","values":[{"k":"a","value":"x"}],"key":"k","reducer":"sum"},
    {"operation":"flatten","values":[],"extra":1},
])
def test_invalid_inputs_raise(payload):
    with pytest.raises(ValueError):
        producer.process(payload)


def test_json_types_are_distinct():
    actual = producer.process({"operation":"constraint","values":[True,1,1.0],
                               "condition":{"operator":"equals","value":1}})
    assert actual["values"] == [False,True,False]


def test_cli_stdin_and_errors():
    payload = {"operation":"flatten","values":[[1,2],[3]]}
    good = subprocess.run([sys.executable,"-I","-S",str(SCRIPT)],input=json.dumps(payload),
                          text=True,capture_output=True,timeout=5)
    assert good.returncode == 0
    assert json.loads(good.stdout)["values"] == [1,2,3]
    bad = subprocess.run([sys.executable,"-I","-S",str(SCRIPT)],input='{"operation":"zip","values":[]}',
                         text=True,capture_output=True,timeout=5)
    assert bad.returncode == 2 and not bad.stdout
