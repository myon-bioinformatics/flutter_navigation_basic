// Pattern 112: DataClean
// 欠損値・外れ値のクリーニング処理。

class Pattern112Result {
  const Pattern112Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern112Result.fromJson(Map<String, dynamic> json) =>
      Pattern112Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern112Result(message: $message)';
}
