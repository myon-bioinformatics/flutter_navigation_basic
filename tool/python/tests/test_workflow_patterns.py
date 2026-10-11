import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import pytest

SCRIPT=Path(__file__).resolve().parents[1]/"workflow_patterns.py"
spec=importlib.util.spec_from_file_location("workflow_patterns",SCRIPT)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

@pytest.mark.parametrize(("operation","kwargs","expect"),[
 ("swap",{"values":[1,2,3],"a":0,"b":2},[3,2,1]),
 ("position_swap",{"values":[1,2,3],"a":0,"b":1},[2,1,3]),
 ("move_top",{"values":[1,2,3],"index":2},[3,1,2]),
 ("move_bottom",{"values":[1,2,3],"index":0},[2,3,1]),
 ("insert_sorted",{"values":[1,3],"value":2},[1,2,3]),
 ("batch",{"values":[1,2,3],"batch_size":2},[[1,2],[3]]),
 ("worker",{"values":[1,2,3],"batch_size":2},[[1,2],[3]]),
 ("checkpoint",{"values":[1,2,3],"checkpoint":2},
  {"processed":[1,2],"remaining":[3],"checkpoint":2}),
 ("scheduler",{"values":["job"],"schedule":[0,100]},
  [{"at_ms":0,"values":["job"]},{"at_ms":100,"values":["job"]}]),
])
def test_real_operations(operation,kwargs,expect):
    assert module.process({"operation":operation,**kwargs})["result"]==expect

@pytest.mark.parametrize("operation",["undo_redo","command","memento"])
def test_state_history_with_undo_and_redo(operation):
    result=module.process({"operation":operation,"values":[1],"commands":[
        {"type":"append","value":2},{"type":"append","value":3},
        {"type":"undo"},{"type":"redo"}]})["result"]
    assert result["values"]==[1,2,3]
    assert result["cursor"]==2

@pytest.mark.parametrize("operation",["transaction","saga","pipeline"])
def test_rollback_on_controlled_failure(operation):
    req={"operation":operation,"values":[1],"commands":[
        {"type":"append","value":2},{"type":"append","value":3}],"fail_at":1}
    r=module.process(req)["result"]
    assert r["committed"] is False and r["rolled_back"] is True
    assert r["values"]==[1]

@pytest.mark.parametrize("operation",["event_driven","pubsub","queue","outbox","event_sourcing","cqrs"])
def test_event_projection(operation):
    r=module.process({"operation":operation,"values":[1],
          "events":[{"type":"append","value":2}]})["result"]
    if operation=="pubsub":
        assert r["subscribers"]==[[{"type":"append","value":2}]]
    elif operation=="cqrs":
        assert r["read_projection"]==[1,2]
    elif operation in ("queue","outbox"):
        assert r["pending"]==[{"type":"append","value":2}]
    else:
        assert r["state"]==[1,2]

@pytest.mark.parametrize("input",[
 {"operation":"swap","values":[1],"a":1,"b":0},
 {"operation":"insert_sorted","values":[3,1],"value":2},
 {"operation":"undo_redo","values":[],"commands":[{"type":"undo"}]},
 {"operation":"transaction","values":[],"commands":[],"fail_at":0},
 {"operation":"checkpoint","values":[1],"checkpoint":2},
 {"operation":"pubsub","values":[],"events":[],"subscribers":0},
 {"operation":"event_driven","values":[],"events":[{"type":"remove","value":1}]},
 {"operation":"worker","values":[1],"batch_size":0},
])
def test_reject_invalid(input):
    with pytest.raises(ValueError):
        module.process(input)

def test_cli_stdin_error_and_json():
    req={"operation":"move_top","values":["a","b"],"index":1}
    run=subprocess.run([sys.executable,"-I","-S",str(SCRIPT)],
        input=json.dumps(req),text=True,capture_output=True,timeout=5)
    assert run.returncode==0
    assert json.loads(run.stdout)["result"]==["b","a"]
    bad=subprocess.run([sys.executable,"-I","-S",str(SCRIPT)],
        input='{"operation":"swap"}',text=True,capture_output=True,timeout=5)
    assert bad.returncode==2 and not bad.stdout
