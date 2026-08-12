// Pattern 177: ExcludeSemantics
// ExcludeSemantics による除外実装。

class Pattern177Result {
  const Pattern177Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern177Result.fromJson(Map<String, dynamic> json) =>
      Pattern177Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern177Result(message: $message)';
}
