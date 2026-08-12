// Pattern 093: JsonList
// JSON 配列の Dart List への変換。

class Pattern093Result {
  const Pattern093Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern093Result.fromJson(Map<String, dynamic> json) =>
      Pattern093Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern093Result(message: $message)';
}
