// Pattern 130: StreamTransform
// Stream の map/where/expand 変換。

class Pattern130Result {
  const Pattern130Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern130Result.fromJson(Map<String, dynamic> json) =>
      Pattern130Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern130Result(message: $message)';
}
