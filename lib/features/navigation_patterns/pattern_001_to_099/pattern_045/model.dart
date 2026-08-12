// Pattern 045: DeepLinkWebUrl
// URL スキーム対応ディープリンク。

class Pattern045Result {
  const Pattern045Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern045Result.fromJson(Map<String, dynamic> json) =>
      Pattern045Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern045Result(message: $message)';
}
