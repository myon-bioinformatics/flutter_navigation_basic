// Pattern 127: NestedNavDeepLink
// ネスト Navigator へのディープリンク。

class Pattern127Result {
  const Pattern127Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern127Result.fromJson(Map<String, dynamic> json) =>
      Pattern127Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern127Result(message: $message)';
}
