// Pattern 039: NamedRoutePreload
// 遷移前にデータをプリロード。

class Pattern039Result {
  const Pattern039Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern039Result.fromJson(Map<String, dynamic> json) =>
      Pattern039Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern039Result(message: $message)';
}
