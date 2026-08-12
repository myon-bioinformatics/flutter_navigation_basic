// Pattern 178: ActionSheet
// iOS 風 ActionSheet 実装。

class Pattern178Result {
  const Pattern178Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern178Result.fromJson(Map<String, dynamic> json) =>
      Pattern178Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern178Result(message: $message)';
}
