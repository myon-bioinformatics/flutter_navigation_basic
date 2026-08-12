// Pattern 134: StreamBuffer2
// Stream のバッファリング処理。

class Pattern134Result {
  const Pattern134Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern134Result.fromJson(Map<String, dynamic> json) =>
      Pattern134Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern134Result(message: $message)';
}
