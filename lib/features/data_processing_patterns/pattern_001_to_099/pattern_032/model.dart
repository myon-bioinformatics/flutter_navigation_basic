// Pattern 032: CursorPagination
// カーソル方式のページネーション。

class Pattern032Result {
  const Pattern032Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern032Result.fromJson(Map<String, dynamic> json) =>
      Pattern032Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern032Result(message: $message)';
}
