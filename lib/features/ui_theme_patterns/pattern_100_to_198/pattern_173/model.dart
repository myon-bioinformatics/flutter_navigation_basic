// Pattern 173: DisplayMode
// 高リフレッシュレート対応 (擬似実装)。

class Pattern173Result {
  const Pattern173Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern173Result.fromJson(Map<String, dynamic> json) =>
      Pattern173Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern173Result(message: $message)';
}
