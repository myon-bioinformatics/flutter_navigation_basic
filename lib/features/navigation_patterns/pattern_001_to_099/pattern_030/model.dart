// Pattern 030: NamedRouteDynamic
// 動的セグメントを含む Named Route。

class Pattern030Result {
  const Pattern030Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern030Result.fromJson(Map<String, dynamic> json) =>
      Pattern030Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern030Result(message: $message)';
}
