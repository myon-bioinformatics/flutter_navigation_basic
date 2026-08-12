// Pattern 111: DataEnrich
// 外部データによるデータ補完。

class Pattern111Result {
  const Pattern111Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern111Result.fromJson(Map<String, dynamic> json) =>
      Pattern111Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern111Result(message: $message)';
}
