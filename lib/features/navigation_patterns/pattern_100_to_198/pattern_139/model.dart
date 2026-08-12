// Pattern 139: NestedNavObserver
// ネスト Navigator のイベント監視。

class Pattern139Result {
  const Pattern139Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern139Result.fromJson(Map<String, dynamic> json) =>
      Pattern139Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern139Result(message: $message)';
}
