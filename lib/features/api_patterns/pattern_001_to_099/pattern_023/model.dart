// Pattern 023: Versioning
// API バージョニング (v1/v2) 対応。

class Pattern023Result {
  const Pattern023Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern023Result.fromJson(Map<String, dynamic> json) =>
      Pattern023Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern023Result(message: $message)';
}
