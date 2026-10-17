import Foundation

let data = FileHandle.standardInput.readDataToEndOfFile()
let input = try JSONSerialization.jsonObject(with: data) as! [String: Any]
func emit(_ result: [String: Any]) throws {
  let output = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
  print(String(data: output, encoding: .utf8)!)
}
switch input["operation"] as! String {
case "array_length":
  try emit(["length": Array(repeating: 0, count: input["count"] as! Int).count])
case "bounds":
  try emit(["value": [1][input["index"] as! Int]])
case "null_assert":
  let value: Int? = nil
  try emit(["value": value!])
case "bad_cast":
  try emit(["value": input["value"] as! Int])
case "invalid_integer":
  try emit(["value": Int(input["value"] as! String)!])
case "invalid_json":
  let text = input["value"] as! String
  _ = try JSONSerialization.jsonObject(with: Data(text.utf8))
  try emit(["unexpectedSuccess": true])
case "divide_zero":
  try emit(["value": 1 / (input["value"] as! Int)])
default:
  fatalError("unsupported operation")
}
