// Pattern 013: IndexedStack
// IndexedStack で状態保持しながら Tab 切り替え。

class Pattern013Result {
  const Pattern013Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern013Result.fromJson(Map<String, dynamic> json) =>
      Pattern013Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern013Result(message: $message)';
}
