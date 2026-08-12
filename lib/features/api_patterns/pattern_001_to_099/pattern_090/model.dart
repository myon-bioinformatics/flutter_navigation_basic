// Pattern 090: LiveFeed
// SSE によるライブフィード表示。

class Pattern090Result {
  const Pattern090Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern090Result.fromJson(Map<String, dynamic> json) =>
      Pattern090Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern090Result(message: $message)';
}
