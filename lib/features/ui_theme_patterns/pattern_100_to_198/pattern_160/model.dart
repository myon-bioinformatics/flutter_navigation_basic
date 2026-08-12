// Pattern 160: IOSBlur
// iOS スタイルのぼかしエフェクト (BackdropFilter)。

class Pattern160Result {
  const Pattern160Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern160Result.fromJson(Map<String, dynamic> json) =>
      Pattern160Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern160Result(message: $message)';
}
