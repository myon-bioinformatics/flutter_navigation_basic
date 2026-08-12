// Pattern 082: RoleBasedNav
// ロールに応じて表示画面を切り替え。

class Pattern082Result {
  const Pattern082Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern082Result.fromJson(Map<String, dynamic> json) =>
      Pattern082Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern082Result(message: $message)';
}
