// Pattern 060: DeepLinkLocalized
// 多言語ロケール付きディープリンク。

class Pattern060Result {
  const Pattern060Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern060Result.fromJson(Map<String, dynamic> json) =>
      Pattern060Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern060Result(message: $message)';
}
