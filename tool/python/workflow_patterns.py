#!/usr/bin/env python3
"""Bounded JSON list operations and in-memory workflow references, patterns 176-198.

Python stdlib only. These are deterministic, single-process reference semantics:
not a database, broker, distributed transaction engine, or persistent scheduler.
"""
from __future__ import annotations
import argparse
import json
import sys

_OPERATIONS = {
    "swap", "move_top", "move_bottom", "insert_sorted", "undo_redo",
    "command", "memento", "position_swap", "batch", "transaction",
    "event_driven", "pubsub", "queue", "saga", "outbox",
    "event_sourcing", "cqrs", "scheduler", "worker", "checkpoint", "pipeline"
}

def require(ok, message):
    if not ok:
        raise ValueError(message)

def obj(x):
    require(isinstance(x, dict), "request must be object")
    return x

def keys(req, permitted, required=()):
    require(set(req) <= set(permitted) and set(required) <= set(req), "invalid keys")

def items(req):
    xs = req.get("values")
    require(isinstance(xs, list) and len(xs) <= 1000, "values must be array <=1000")
    return list(xs)

def index(value, size, allow_end=False):
    require(type(value) is int and 0 <= value < size + int(allow_end), "index out of range")
    return value

def bounded_commands(raw):
    require(isinstance(raw, list) and len(raw) <= 1000, "commands must be array <=1000")
    return raw

def mutate(xs, c):
    c = obj(c)
    typ = c.get("type")
    if typ == "append":
        keys(c, ("type", "value"), ("type", "value"))
        xs.append(c["value"])
    elif typ == "remove_last":
        keys(c, ("type",), ("type",))
        require(bool(xs), "empty list")
        xs.pop()
    elif typ == "replace":
        keys(c, ("type", "index", "value"), ("type", "index", "value"))
        xs[index(c["index"], len(xs))] = c["value"]
    else:
        raise ValueError("unknown command")
    require(len(xs) <= 1000, "list too large")
    return xs

def process(request):
    r = obj(request)
    operation = r.get("operation")
    require(type(operation) is str and operation in _OPERATIONS, "unknown operation")
    keys(r, ("operation","values","a","b","index","value","commands","batch_size",
             "subscribers","events","fail_at","checkpoint","schedule"))
    value_ops = {"swap","position_swap","move_top","move_bottom","insert_sorted",
                 "undo_redo","command","memento","batch","transaction",
                 "event_driven","pubsub","queue","saga","outbox",
                 "event_sourcing","cqrs","scheduler","worker","checkpoint","pipeline"}
    xs = items(r) if operation in value_ops else []
    if operation in ("swap","position_swap"):
        keys(r, ("operation","values","a","b"), ("operation","values","a","b"))
        a,b = index(r["a"],len(xs)),index(r["b"],len(xs))
        xs[a],xs[b]=xs[b],xs[a]
        result=xs
    elif operation in ("move_top","move_bottom"):
        keys(r, ("operation","values","index"), ("operation","values","index"))
        v=xs.pop(index(r["index"],len(xs)))
        xs.insert(0 if operation=="move_top" else len(xs),v)
        result=xs
    elif operation=="insert_sorted":
        keys(r, ("operation","values","value"), ("operation","values","value"))
        require(all(type(x) in (int,float) for x in xs+[r["value"]]),"numeric sort only")
        require(all(xs[i]<=xs[i+1] for i in range(len(xs)-1)), "input not sorted")
        xs.append(r["value"])
        xs.sort()
        result=xs
    elif operation in ("undo_redo","command","memento"):
        keys(r, ("operation","values","commands"), ("operation","values","commands"))
        history=[list(xs)]
        cursor=0
        for cmd in bounded_commands(r["commands"]):
            if isinstance(cmd,dict) and cmd.get("type")=="undo":
                keys(cmd,("type",),("type",))
                require(cursor>0,"cannot undo")
                cursor-=1
            elif isinstance(cmd,dict) and cmd.get("type")=="redo":
                keys(cmd,("type",),("type",))
                require(cursor+1<len(history),"cannot redo")
                cursor+=1
            else:
                history=history[:cursor+1]
                current=mutate(list(history[-1]),cmd)
                history.append(list(current))
                cursor+=1
        result={"values":history[cursor],"history":history,"cursor":cursor}
    elif operation in ("batch","worker","scheduler"):
        keys(r, ("operation","values","batch_size","schedule"))
        size=r.get("batch_size",2)
        require(type(size) is int and 1<=size<=1000,"invalid batch size")
        if operation=="scheduler":
            schedule=r.get("schedule",[])
            require(isinstance(schedule,list) and len(schedule)<=1000
                    and all(type(t) is int and 0<=t<=60000 for t in schedule),"invalid schedule")
            result=[{"at_ms":t,"values":list(xs)} for t in schedule]
        else:
            result=[xs[i:i+size] for i in range(0,len(xs),size)]
    elif operation in ("transaction","saga","pipeline"):
        keys(r, ("operation","values","commands","fail_at"), ("operation","values","commands"))
        commands=bounded_commands(r["commands"])
        failed=r.get("fail_at")
        require(failed is None or (type(failed) is int and 0<=failed<len(commands)),"invalid fail_at")
        original=list(xs)
        log=[]
        for i,c in enumerate(commands):
            if i==failed:
                xs=list(original)
                result={"committed":False,"values":xs,"applied":log,"rolled_back":True}
                break
            mutate(xs,c)
            log.append(i)
        else:
            result={"committed":True,"values":xs,"applied":log,"rolled_back":False}
    elif operation in ("event_driven","pubsub","queue","outbox","event_sourcing","cqrs"):
        keys(r,("operation","values","events","subscribers"),("operation","values","events"))
        events=r["events"]
        require(isinstance(events,list) and len(events)<=1000,"events must be array <=1000")
        for e in events:
            require(isinstance(e,dict) and set(e)=={"type","value"} and e["type"]=="append","invalid event")
        log=list(events)
        current=list(xs)
        for event in events:
            current.append(event["value"])
        require(len(current)<=1000,"result too large")
        if operation=="pubsub":
            n=r.get("subscribers",1)
            require(type(n) is int and 1<=n<=16,"invalid subscribers")
            result={"subscribers":[list(log) for _ in range(n)],"state":current}
        elif operation in ("outbox","queue"):
            result={"pending":log,"state":current}
        elif operation=="cqrs":
            result={"write_state":current,"read_projection":list(current)}
        else:
            result={"log":log,"state":current}
    elif operation=="checkpoint":
        keys(r,("operation","values","checkpoint"),("operation","values","checkpoint"))
        cursor=r.get("checkpoint",0)
        require(type(cursor) is int and 0<=cursor<=len(xs),"invalid checkpoint")
        result={"processed":xs[:cursor],"remaining":xs[cursor:],"checkpoint":cursor}
    else:
        raise ValueError("unsupported operation")
    return {"schema":"workflow-patterns/1","operation":operation,"result":result}

def main(argv=None):
    parser=argparse.ArgumentParser()
    parser.add_argument("--input",default="-")
    args=parser.parse_args(argv)
    try:
        if args.input=="-": raw=sys.stdin.read()
        else:
            with open(args.input,encoding="utf-8") as file: raw=file.read()
        payload=json.loads(raw,parse_constant=lambda x:(_ for _ in ()).throw(ValueError("nonfinite value")))
        print(json.dumps(process(payload),sort_keys=True,ensure_ascii=False,allow_nan=False))
        return 0
    except (ValueError,TypeError,OSError,RecursionError) as e:
        print(f"invalid input: {e}",file=sys.stderr)
        return 2

if __name__=="__main__":
    raise SystemExit(main())
