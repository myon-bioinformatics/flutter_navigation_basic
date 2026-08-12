// Pattern 091: MaintenanceMode
// メンテナンスモード時の画面切り替え。

class Pattern091Result {
  const Pattern091Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern091Result.fromJson(Map<String, dynamic> json) =>
      Pattern091Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern091Result(message: $message)';
}
