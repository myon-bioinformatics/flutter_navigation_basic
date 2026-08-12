// Pattern 078: NavigationRailExtended
// 拡張表示対応 NavigationRail。

class Pattern078Result {
  const Pattern078Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern078Result.fromJson(Map<String, dynamic> json) =>
      Pattern078Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern078Result(message: $message)';
}
