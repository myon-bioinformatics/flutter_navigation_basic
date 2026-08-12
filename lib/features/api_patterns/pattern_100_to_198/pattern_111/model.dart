// Pattern 111: XmlParse
// XML 文字列のパース (標準ライブラリ範囲)。

class Pattern111Result {
  const Pattern111Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern111Result.fromJson(Map<String, dynamic> json) =>
      Pattern111Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern111Result(message: $message)';
}
