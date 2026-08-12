// Pattern 163: Bloc
// BLoC パターンの擬似実装。

class Pattern163Result {
  const Pattern163Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern163Result.fromJson(Map<String, dynamic> json) =>
      Pattern163Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern163Result(message: $message)';
}
