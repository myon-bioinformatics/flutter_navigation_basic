"""Independent Python implementation of the explicit nonnegative-length contract."""
import json
import sys

count = json.load(sys.stdin)["count"]
if type(count) is not int or count < 0:
    raise ValueError("negative array length")
items = [0 for _ in range(count)]
print(json.dumps({"length": len(items)}))
