// Pattern 121: ErrorHandlingBasic
// HTTP エラーコードに応じた例外処理。

class Pattern121Result {
  const Pattern121Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern121Result.fromJson(Map<String, dynamic> json) =>
      Pattern121Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern121Result(message: $message)';
}
