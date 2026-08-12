// Pattern 103: YamlRead
// YAML 文字列のパース (標準ライブラリ範囲)。

class Pattern103Result {
  const Pattern103Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern103Result.fromJson(Map<String, dynamic> json) =>
      Pattern103Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern103Result(message: $message)';
}
