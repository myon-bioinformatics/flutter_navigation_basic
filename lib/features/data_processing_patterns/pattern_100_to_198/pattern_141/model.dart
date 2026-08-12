// Pattern 141: CancelableOp
// キャンセル可能な非同期操作実装。

class Pattern141Result {
  const Pattern141Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern141Result.fromJson(Map<String, dynamic> json) =>
      Pattern141Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern141Result(message: $message)';
}
