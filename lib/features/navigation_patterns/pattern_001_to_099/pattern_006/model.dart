// Pattern 006: PushNamed
// ルート名文字列で遷移する Named Push。

class Pattern006Result {
  const Pattern006Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern006Result.fromJson(Map<String, dynamic> json) =>
      Pattern006Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern006Result(message: $message)';
}
