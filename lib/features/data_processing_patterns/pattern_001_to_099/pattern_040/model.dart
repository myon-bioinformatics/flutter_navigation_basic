// Pattern 040: PageSize
// ページサイズ変更対応ページング。

class Pattern040Result {
  const Pattern040Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern040Result.fromJson(Map<String, dynamic> json) =>
      Pattern040Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern040Result(message: $message)';
}
