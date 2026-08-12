// Pattern 051: PermissionCheck
// 権限確認後に API 呼び出し。

class Pattern051Result {
  const Pattern051Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern051Result.fromJson(Map<String, dynamic> json) =>
      Pattern051Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern051Result(message: $message)';
}
