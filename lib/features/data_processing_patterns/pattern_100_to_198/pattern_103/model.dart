// Pattern 103: DataNormalize
// データ正規化 (文字列トリム、大文字小文字統一等)。

class Pattern103Result {
  const Pattern103Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern103Result.fromJson(Map<String, dynamic> json) =>
      Pattern103Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern103Result(message: $message)';
}
