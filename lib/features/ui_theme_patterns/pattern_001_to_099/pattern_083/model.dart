// Pattern 083: IconTheme
// IconTheme のカスタマイズ。

class Pattern083Result {
  const Pattern083Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern083Result.fromJson(Map<String, dynamic> json) =>
      Pattern083Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern083Result(message: $message)';
}
