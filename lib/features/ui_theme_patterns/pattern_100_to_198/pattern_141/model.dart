// Pattern 141: SafeArea
// SafeArea による端末ノッチ/バー対応。

class Pattern141Result {
  const Pattern141Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern141Result.fromJson(Map<String, dynamic> json) =>
      Pattern141Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern141Result(message: $message)';
}
