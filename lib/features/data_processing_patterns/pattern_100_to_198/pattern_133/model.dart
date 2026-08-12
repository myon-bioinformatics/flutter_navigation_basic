// Pattern 133: StreamThrottle
// Stream のスロットリング処理。

class Pattern133Result {
  const Pattern133Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern133Result.fromJson(Map<String, dynamic> json) =>
      Pattern133Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern133Result(message: $message)';
}
