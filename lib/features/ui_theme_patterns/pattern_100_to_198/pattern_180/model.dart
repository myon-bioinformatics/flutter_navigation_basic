// Pattern 180: FocusTraversal
// FocusTraversalGroup による Tab 移動制御。

class Pattern180Result {
  const Pattern180Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern180Result.fromJson(Map<String, dynamic> json) =>
      Pattern180Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern180Result(message: $message)';
}
