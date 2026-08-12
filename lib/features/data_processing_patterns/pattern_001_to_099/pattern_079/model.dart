// Pattern 079: LazyInit
// 遅延初期化パターン。

class Pattern079Result {
  const Pattern079Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern079Result.fromJson(Map<String, dynamic> json) =>
      Pattern079Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern079Result(message: $message)';
}
