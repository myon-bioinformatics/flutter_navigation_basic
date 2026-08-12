// Pattern 046: CupertinoSegment
// CupertinoSegmentedControl の実装。

class Pattern046Result {
  const Pattern046Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern046Result.fromJson(Map<String, dynamic> json) =>
      Pattern046Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern046Result(message: $message)';
}
