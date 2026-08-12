// Pattern 078: ComputeCache
// 計算結果キャッシュ (メモ化)。

class Pattern078Result {
  const Pattern078Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern078Result.fromJson(Map<String, dynamic> json) =>
      Pattern078Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern078Result(message: $message)';
}
