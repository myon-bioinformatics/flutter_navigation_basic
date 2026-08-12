// Pattern 075: DrawerPersistent
// 常に表示される Persistent Drawer。

class Pattern075Result {
  const Pattern075Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern075Result.fromJson(Map<String, dynamic> json) =>
      Pattern075Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern075Result(message: $message)';
}
