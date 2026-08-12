// Pattern 023: NamedRouteResult
// Named Route の遷移結果を受け取る。

class Pattern023Result {
  const Pattern023Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern023Result.fromJson(Map<String, dynamic> json) =>
      Pattern023Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern023Result(message: $message)';
}
