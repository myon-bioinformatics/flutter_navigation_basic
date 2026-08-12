// Pattern 117: ModalBarrier
// モーダルバリアでバック操作をブロック。

class Pattern117Result {
  const Pattern117Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern117Result.fromJson(Map<String, dynamic> json) =>
      Pattern117Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern117Result(message: $message)';
}
