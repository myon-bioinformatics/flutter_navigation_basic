// Pattern 006: QueryParams
// クエリパラメータ付き GET リクエスト。

class Pattern006Result {
  const Pattern006Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern006Result.fromJson(Map<String, dynamic> json) =>
      Pattern006Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern006Result(message: $message)';
}
