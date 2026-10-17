import Foundation

let data = FileHandle.standardInput.readDataToEndOfFile()
let input = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let items = Array(repeating: 0, count: input["count"] as! Int)
print("{\"length\":\(items.count)}")
