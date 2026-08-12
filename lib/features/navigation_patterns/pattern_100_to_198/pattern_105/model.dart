// Pattern 105: CustomBackButton
// カスタムバックボタン実装。

class Pattern105Result {
  const Pattern105Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern105Result.fromJson(Map<String, dynamic> json) =>
      Pattern105Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern105Result(message: $message)';
}
