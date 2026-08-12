// Pattern 084: StreamBuffer
// ストリームバッファリング実装。

class Pattern084Result {
  const Pattern084Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern084Result.fromJson(Map<String, dynamic> json) =>
      Pattern084Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern084Result(message: $message)';
}
