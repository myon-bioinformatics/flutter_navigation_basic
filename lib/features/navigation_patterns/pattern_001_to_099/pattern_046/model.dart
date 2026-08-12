// Pattern 046: DeepLinkQueryParam
// クエリパラメータ付きディープリンク。

class Pattern046Result {
  const Pattern046Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern046Result.fromJson(Map<String, dynamic> json) =>
      Pattern046Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern046Result(message: $message)';
}
