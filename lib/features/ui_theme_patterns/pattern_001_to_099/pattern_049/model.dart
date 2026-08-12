// Pattern 049: CupertinoTimer
// CupertinoTimerPicker の実装。

class Pattern049Result {
  const Pattern049Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern049Result.fromJson(Map<String, dynamic> json) =>
      Pattern049Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern049Result(message: $message)';
}
