// Pattern 139: NestedScroll
// NestedScrollView による複合スクロール。

class Pattern139Result {
  const Pattern139Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern139Result.fromJson(Map<String, dynamic> json) =>
      Pattern139Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern139Result(message: $message)';
}
