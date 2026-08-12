// Pattern 069: TabBarDynamic
// 動的にタブを追加・削除。

class Pattern069Result {
  const Pattern069Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern069Result.fromJson(Map<String, dynamic> json) =>
      Pattern069Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern069Result(message: $message)';
}
