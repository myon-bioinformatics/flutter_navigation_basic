// Pattern 135: StreamWindow
// Stream のウィンドウ集計処理。

class Pattern135Result {
  const Pattern135Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern135Result.fromJson(Map<String, dynamic> json) =>
      Pattern135Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern135Result(message: $message)';
}
