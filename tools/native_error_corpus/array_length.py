"""Independent Python operations for the explicit first error sweep."""
import json
import sys

request = json.load(sys.stdin)
operation = request.get("operation", "array_length")
if operation == "array_length":
    count = request["count"]
    if type(count) is not int or count < 0:
        raise ValueError("negative array length")
    result = {"length": len([0 for _ in range(count)])}
elif operation == "bounds":
    result = {"value": [1][request["index"]]}
elif operation == "null_assert":
    result = {"value": request["value"].to_string()}
elif operation == "bad_cast":
    value = request["value"]
    if type(value) is not int:
        raise TypeError("integer cast requires an integer")
    result = {"value": value}
elif operation == "invalid_integer":
    result = {"value": int(request["value"])}
elif operation == "invalid_json":
    result = {"value": json.loads(request["value"])}
elif operation == "divide_zero":
    result = {"value": 1 // request["value"]}
else:
    raise ValueError("unsupported operation")
print(json.dumps(result))
