// Pattern 196: Worker
// バックグラウンドワーカーの実装。

class Pattern196Result {
  const Pattern196Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern196Result.fromJson(Map<String, dynamic> json) =>
      Pattern196Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern196Result(message: $message)';
}
