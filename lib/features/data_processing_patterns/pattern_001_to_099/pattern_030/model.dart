// Pattern 030: DistinctFilter
// 重複排除フィルタリング。

class Pattern030Result {
  const Pattern030Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern030Result.fromJson(Map<String, dynamic> json) =>
      Pattern030Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern030Result(message: $message)';
}
