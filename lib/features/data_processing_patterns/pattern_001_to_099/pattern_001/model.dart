// Pattern 001: FilterBasic
// リストのシンプルなフィルタリング実装。

class Pattern001Result {
  const Pattern001Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern001Result.fromJson(Map<String, dynamic> json) =>
      Pattern001Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern001Result(message: $message)';
}
