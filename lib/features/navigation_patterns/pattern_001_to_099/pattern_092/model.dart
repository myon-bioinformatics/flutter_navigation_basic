// Pattern 092: ForceUpdate
// 強制アップデート画面への遷移制御。

class Pattern092Result {
  const Pattern092Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern092Result.fromJson(Map<String, dynamic> json) =>
      Pattern092Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern092Result(message: $message)';
}
