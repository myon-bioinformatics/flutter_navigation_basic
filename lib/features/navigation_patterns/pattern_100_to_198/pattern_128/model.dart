// Pattern 128: NestedNavState
// ネスト Navigator の状態保持。

class Pattern128Result {
  const Pattern128Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern128Result.fromJson(Map<String, dynamic> json) =>
      Pattern128Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern128Result(message: $message)';
}
