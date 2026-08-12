// Pattern 115: RouteInfo
// 現在のルート情報を取得・表示。

class Pattern115Result {
  const Pattern115Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern115Result.fromJson(Map<String, dynamic> json) =>
      Pattern115Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern115Result(message: $message)';
}
