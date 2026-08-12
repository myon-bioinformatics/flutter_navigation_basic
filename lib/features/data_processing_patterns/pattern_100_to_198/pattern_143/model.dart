// Pattern 143: ProgressStream
// 進捗報告付き非同期処理。

class Pattern143Result {
  const Pattern143Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern143Result.fromJson(Map<String, dynamic> json) =>
      Pattern143Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern143Result(message: $message)';
}
