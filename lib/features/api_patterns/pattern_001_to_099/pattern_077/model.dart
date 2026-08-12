// Pattern 077: ShortPolling
// Short Polling + インターバル制御。

class Pattern077Result {
  const Pattern077Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern077Result.fromJson(Map<String, dynamic> json) =>
      Pattern077Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern077Result(message: $message)';
}
