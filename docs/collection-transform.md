# Data transformation CLI (patterns 114–120)

Run with Python 3.10+ and standard library only:

```sh
echo '{"operation":"flatten","values":[[1,2],[3]]}' | python -S tool/python/collection_transform.py
python -m pytest tool/python/tests/test_collection_transform.py -q
```

All requests are JSON objects and contain `operation` and a `values` array.
Responses use `{"schema":"collection-transform/1","operation":"...","values":...}`.
Bad input returns exit 2 with no JSON on stdout. Order is stable; input isn't changed.

- **114 schema_validation:** `schema` defines JSON types, optional object
  `properties`/`required`/`additional_properties` and array `items`.
  Returns a boolean for each input value; this is a deliberately bounded schema
  subset, not complete JSON Schema.
- **115 constraint:** `condition` supports `equals`, `not_equals`,
  `greater_than`, `less_than`, `type`, and `not_null`; returns booleans.
- **116 pipeline:** non-empty `steps` array with `strip`/`lower`/`upper`
  for strings and `add`/`multiply` for numbers.
- **117 map_reduce:** `key` is a row field and `reducer` is `count` or
  `sum` (sum reads numeric `value`). Groups preserve first-seen order.
- **118 flatten:** recursively flattens nested arrays, retaining leaf order.
- **119 partition:** `condition` uses the same predicate; returns
  `{"matched":[...],"unmatched":[...]}`.
- **120 zip:** `other` is another array; pairs up to shortest by default,
  or requires equal lengths with `strict:true`.

This does **not** claim that Flutter executes Python on iOS/Android/web.
A separate asset or runtime boundary is required for UI integration.
Old Dart services in these patterns have no implemented logic; deleting those
placeholders must not be confused with proving live UI execution.
