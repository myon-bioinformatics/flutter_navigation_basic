// Pattern 153: LastModified
// Last-Modified を使ったキャッシュ制御。

class Pattern153Result {
  const Pattern153Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern153Result.fromJson(Map<String, dynamic> json) =>
      Pattern153Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern153Result(message: $message)';
}
