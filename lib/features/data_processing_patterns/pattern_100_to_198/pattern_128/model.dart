// Pattern 128: StreamController
// StreamController による手動 Stream 制御。

class Pattern128Result {
  const Pattern128Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern128Result.fromJson(Map<String, dynamic> json) =>
      Pattern128Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern128Result(message: $message)';
}
