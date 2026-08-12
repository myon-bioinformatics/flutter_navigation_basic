// Pattern 196: WidgetToRoute
// ウィジェット状態をルート引数として渡す。

class Pattern196Result {
  const Pattern196Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern196Result.fromJson(Map<String, dynamic> json) =>
      Pattern196Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern196Result(message: $message)';
}
