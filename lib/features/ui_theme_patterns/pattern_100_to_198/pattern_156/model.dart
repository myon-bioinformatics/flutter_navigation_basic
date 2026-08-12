// Pattern 156: MacOSMenu
// macOS メニューバー項目の追加。

class Pattern156Result {
  const Pattern156Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern156Result.fromJson(Map<String, dynamic> json) =>
      Pattern156Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern156Result(message: $message)';
}
