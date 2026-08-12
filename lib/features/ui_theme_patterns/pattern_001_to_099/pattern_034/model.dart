// Pattern 034: CupertinoButton
// CupertinoButton のスタイル。

class Pattern034Result {
  const Pattern034Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern034Result.fromJson(Map<String, dynamic> json) =>
      Pattern034Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern034Result(message: $message)';
}
