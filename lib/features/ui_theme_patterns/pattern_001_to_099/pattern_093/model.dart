// Pattern 093: ManualDarkMode
// ユーザー手動でのダークモード切り替え。

class Pattern093Result {
  const Pattern093Result({required this.message});
  final String message;

  Map<String, dynamic> toJson() => {'message': message};

  factory Pattern093Result.fromJson(Map<String, dynamic> json) =>
      Pattern093Result(message: json['message'] as String);

  @override
  String toString() => 'Pattern093Result(message: $message)';
}
