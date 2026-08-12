// Pattern 113: ProtobufMock
// Protocol Buffers の擬似実装。

class Pattern113Result {
  const Pattern113Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern113Result.fromJson(Map<String, dynamic> json) =>
      Pattern113Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern113Result(message: $message)';
}
