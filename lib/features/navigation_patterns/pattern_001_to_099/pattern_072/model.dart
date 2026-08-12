// Pattern 072: DrawerEndDrawer
// 右側から表示される EndDrawer。

class Pattern072Result {
  const Pattern072Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern072Result.fromJson(Map<String, dynamic> json) =>
      Pattern072Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern072Result(message: $message)';
}
